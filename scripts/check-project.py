"""Validate project wiring without claiming to compile Swift or verify signing."""
from pathlib import Path
import plistlib
import re
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent.parent
text = (root / 'FORMStudy.xcodeproj/project.pbxproj').read_text()
pattern = r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+'
tokens = [t for t in re.findall(pattern, text) if not t.startswith(('//', '/*'))]
position = 0


def take():
    global position
    token = tokens[position]
    position += 1
    return token


def expect(token):
    actual = take()
    assert actual == token, (actual, token)


def value():
    token = take()
    if token == '{':
        result = {}
        while tokens[position] != '}':
            key = value()
            expect('=')
            assert key not in result, f'Duplicate key: {key}'
            result[key] = value()
            expect(';')
        expect('}')
        return result
    if token == '(':
        result = []
        while tokens[position] != ')':
            result.append(value())
            if tokens[position] != ')':
                expect(',')
        expect(')')
        return result
    return token[1:-1] if token.startswith('"') else token


project = value()
assert position == len(tokens)
objects = project['objects']
main = objects[project['rootObject']]
targets = {objects[t]['name']: objects[t] for t in main['targets']}
assert set(targets) == {'FORMStudy', 'FORMStudyWidget'}
paths = {}


def walk(group_id, base):
    group = objects[group_id]
    base = base / group.get('path', '')
    for child_id in group.get('children', []):
        child = objects[child_id]
        if child['isa'] == 'PBXGroup':
            walk(child_id, base)
        elif child.get('sourceTree') == '<group>':
            paths[child_id] = base / child['path']
            assert paths[child_id].exists(), paths[child_id]
            if paths[child_id].is_dir():
                assert paths[child_id].name.endswith('.xcassets'), paths[child_id]


walk(main['mainGroup'], root)
teams = set()
for name, target in targets.items():
    configs = objects[target['buildConfigurationList']]['buildConfigurations']
    assert {objects[c]['name'] for c in configs} == {'Debug', 'Release'}
    for c in configs:
        settings = objects[c]['buildSettings']
        expected_id = 'jp.ryukawasaki.formstudy' + ('.widget' if name.endswith('Widget') else '')
        assert settings['PRODUCT_BUNDLE_IDENTIFIER'] == expected_id
        assert settings['CODE_SIGN_STYLE'] == 'Automatic'
        teams.add(settings['DEVELOPMENT_TEAM'])
        info = plistlib.loads((root / settings['INFOPLIST_FILE']).read_bytes())
        if name == 'FORMStudy':
            assert settings['ASSETCATALOG_COMPILER_APPICON_NAME'] == 'AppIcon'
            assert info['NSSupportsLiveActivities'] is True
        else:
            assert settings['APPLICATION_EXTENSION_API_ONLY'] == 'YES'
            assert info['NSExtension']['NSExtensionPointIdentifier'] == 'com.apple.widgetkit-extension'
    sources = [objects[b]['fileRef'] for phase in target['buildPhases']
               if objects[phase]['isa'] == 'PBXSourcesBuildPhase' for b in objects[phase]['files']]
    assert root / 'FORMStudy/StudyTimerAttributes.swift' in [paths[s] for s in sources]
assert len(teams) == 1
widget_id = next(t for t in main['targets'] if objects[t]['name'] == 'FORMStudyWidget')
assert any(objects[d]['target'] == widget_id for d in targets['FORMStudy']['dependencies'])
embedded = [objects[b] for p in targets['FORMStudy']['buildPhases']
            if objects[p]['isa'] == 'PBXCopyFilesBuildPhase' and objects[p]['dstSubfolderSpec'] == '13'
            for b in objects[p]['files']]
assert any(b['fileRef'] == targets['FORMStudyWidget']['productReference']
           and 'CodeSignOnCopy' in b['settings']['ATTRIBUTES'] for b in embedded)
scheme = ET.parse(root / 'FORMStudy.xcodeproj/xcshareddata/xcschemes/FORMStudy.xcscheme')
assert {x.attrib['BlueprintIdentifier'] for x in scheme.findall('./BuildAction/BuildActionEntries/BuildActionEntry/BuildableReference')} == set(main['targets'])
print('PASS: project parsed; source files, both configurations, matching teams, extension embedding, shared attributes, Live Activity plist, and shared scheme validated.')
print('Swift compilation, provisioning, and device behavior require Xcode and an iPhone.')
