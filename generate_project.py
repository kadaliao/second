#!/usr/bin/env python3
"""
Generate a proper Xcode project.pbxproj file with all Swift files
"""
import hashlib

def generate_id(name):
    """Generate a unique 24-character hex ID from a name"""
    hash_obj = hashlib.md5(name.encode())
    return hash_obj.hexdigest()[:24].upper()

# Define all Swift source files
swift_files = [
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

# Generate IDs for each file
file_refs = {}
build_files = {}

for folder, filename in swift_files:
    file_id = generate_id(f"fileref_{folder}_{filename}")
    build_id = generate_id(f"build_{folder}_{filename}")
    file_refs[f"{folder}/{filename}"] = file_id
    build_files[f"{folder}/{filename}"] = build_id

# Generate other IDs
ids = {
    'app': generate_id('Second.app'),
    'info_plist': generate_id('Info.plist'),
    'entitlements': generate_id('Second.entitlements'),
    'frameworks_phase': generate_id('Frameworks'),
    'sources_phase': generate_id('Sources'),
    'resources_phase': generate_id('Resources'),
    'target': generate_id('Second_target'),
    'project': generate_id('Project'),
    'group_root': generate_id('group_root'),
    'group_products': generate_id('group_products'),
    'group_second': generate_id('group_second'),
    'group_app': generate_id('group_app'),
    'group_models': generate_id('group_models'),
    'group_services': generate_id('group_services'),
    'group_utilities': generate_id('group_utilities'),
    'group_viewmodels': generate_id('group_viewmodels'),
    'group_views': generate_id('group_views'),
    'group_components': generate_id('group_components'),
    'group_resources': generate_id('group_resources'),
    'config_debug': generate_id('config_debug'),
    'config_release': generate_id('config_release'),
    'config_list_project': generate_id('config_list_project'),
    'config_list_target': generate_id('config_list_target'),
}

print("Generating project.pbxproj...")
print(f"Total Swift files: {len(swift_files)}")

# Generate PBXBuildFile section
def generate_build_files():
    lines = ["/* Begin PBXBuildFile section */"]
    for path, build_id in build_files.items():
        file_id = file_refs[path]
        filename = path.split('/')[-1]
        lines.append(f"\t\t{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {filename} */; }};")
    lines.append("/* End PBXBuildFile section */")
    return '\n'.join(lines)

# Generate PBXFileReference section
def generate_file_references():
    lines = ["/* Begin PBXFileReference section */"]
    lines.append(f"\t\t{ids['app']} /* Second.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Second.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    lines.append(f"\t\t{ids['info_plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    lines.append(f"\t\t{ids['entitlements']} /* Second.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Second.entitlements; sourceTree = \"<group>\"; }};")

    for path, file_id in file_refs.items():
        filename = path.split('/')[-1]
        lines.append(f"\t\t{file_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};")

    lines.append("/* End PBXFileReference section */")
    return '\n'.join(lines)

# Generate PBXGroup section
def generate_groups():
    lines = ["/* Begin PBXGroup section */"]

    # Root group
    lines.append(f"\t\t{ids['group_root']} = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{ids['group_second']} /* Second */,")
    lines.append(f"\t\t\t\t{ids['group_products']} /* Products */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Products group
    lines.append(f"\t\t{ids['group_products']} /* Products */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{ids['app']} /* Second.app */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tname = Products;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Second group
    lines.append(f"\t\t{ids['group_second']} /* Second */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{ids['group_app']} /* App */,")
    lines.append(f"\t\t\t\t{ids['group_models']} /* Models */,")
    lines.append(f"\t\t\t\t{ids['group_services']} /* Services */,")
    lines.append(f"\t\t\t\t{ids['group_utilities']} /* Utilities */,")
    lines.append(f"\t\t\t\t{ids['group_viewmodels']} /* ViewModels */,")
    lines.append(f"\t\t\t\t{ids['group_views']} /* Views */,")
    lines.append(f"\t\t\t\t{ids['group_resources']} /* Resources */,")
    lines.append(f"\t\t\t\t{ids['info_plist']} /* Info.plist */,")
    lines.append(f"\t\t\t\t{ids['entitlements']} /* Second.entitlements */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = Second;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # App group
    lines.append(f"\t\t{ids['group_app']} /* App */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    lines.append(f"\t\t\t\t{file_refs['App/SecondApp.swift']} /* SecondApp.swift */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = App;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    # Models group
    lines.append(f"\t\t{ids['group_models']} /* Models */ = {{")
    lines.append(f"\t\t\tisa = PBXGroup;")
    lines.append(f"\t\t\tchildren = (")
    for path in ['Models/Token.swift', 'Models/TOTPParameters.swift', 'Models/Vault.swift']:
        filename = path.split('/')[-1]
        lines.append(f"\t\t\t\t{file_refs[path]} /* {filename} */,")
    lines.append(f"\t\t\t);")
    lines.append(f"\t\t\tpath = Models;")
    lines.append(f"\t\t\tsourceTree = \"<group>\";")
    lines.append(f"\t\t}};")

    lines.append("/* End PBXGroup section */")
    return '\n'.join(lines)
