#!/usr/bin/env python3
import hashlib

def gen_id(name):
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

# All Swift files
files = [
    ('App', 'SecondApp.swift'),
    ('Models', 'Token.swift'),
    ('Models', 'TOTPParameters.swift'),
    ('Models', 'Vault.swift'),
    ('Services', 'Base32Decoder.swift'),
    ('Services', 'EncryptionService.swift'),
    ('Services', 'iCloudSyncService.swift'),
    ('Services', 'KeychainService.swift'),
    ('Services', 'QRCodeParser.swift'),
    ('Services', 'TOTPGenerator.swift'),
    ('Utilities', 'ClipboardHelper.swift'),
    ('Utilities', 'Logger.swift'),
    ('ViewModels', 'AddTokenViewModel.swift'),
    ('ViewModels', 'TokenListViewModel.swift'),
    ('Views', 'AddTokenView.swift'),
    ('Views', 'TokenListView.swift'),
    ('Views/Components', 'CountdownTimerView.swift'),
    ('Views/Components', 'EmptyStateView.swift'),
    ('Views/Components', 'QRCodeScannerView.swift'),
    ('Views/Components', 'TokenCardView.swift'),
]

# Generate IDs
file_ids = {f'{folder}/{name}': gen_id(f'file_{folder}_{name}') for folder, name in files}
build_ids = {f'{folder}/{name}': gen_id(f'build_{folder}_{name}') for folder, name in files}

ids = {
    'app': gen_id('Second.app'),
    'info_plist': gen_id('Info.plist'),
    'entitlements': gen_id('Second.entitlements'),
    'frameworks_phase': gen_id('Frameworks'),
    'sources_phase': gen_id('Sources'),
    'resources_phase': gen_id('Resources'),
    'target': gen_id('Second_target'),
    'project': gen_id('Project'),
    'group_root': gen_id('group_root'),
    'group_products': gen_id('group_products'),
    'group_second': gen_id('group_second'),
    'group_app': gen_id('group_app'),
    'group_models': gen_id('group_models'),
    'group_services': gen_id('group_services'),
    'group_utilities': gen_id('group_utilities'),
    'group_viewmodels': gen_id('group_viewmodels'),
    'group_views': gen_id('group_views'),
    'group_components': gen_id('group_components'),
    'group_resources': gen_id('group_resources'),
    'config_debug': gen_id('config_debug'),
    'config_release': gen_id('config_release'),
    'config_list_project': gen_id('config_list_project'),
    'config_list_target': gen_id('config_list_target'),
}

# Start building the project file
output = []
output.append('// !$*UTF8*$!')
output.append('{')
output.append('\tarchiveVersion = 1;')
output.append('\tclasses = {')
output.append('\t};')
output.append('\tobjectVersion = 56;')
output.append('\tobjects = {')
output.append('')

# PBXBuildFile section
output.append('/* Begin PBXBuildFile section */')
for path, bid in sorted(build_ids.items()):
    fid = file_ids[path]
    name = path.split('/')[-1]
    output.append(f'\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};')
output.append('/* End PBXBuildFile section */')
output.append('')

# PBXFileReference section
output.append('/* Begin PBXFileReference section */')
output.append(f'\t\t{ids["app"]} /* Second.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Second.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
output.append(f'\t\t{ids["info_plist"]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
output.append(f'\t\t{ids["entitlements"]} /* Second.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Second.entitlements; sourceTree = "<group>"; }};')
for path, fid in sorted(file_ids.items()):
    name = path.split('/')[-1]
    output.append(f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};')
output.append('/* End PBXFileReference section */')
output.append('')

print('\n'.join(output))
