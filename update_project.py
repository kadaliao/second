#!/usr/bin/env python3
"""
Script to update Xcode project.pbxproj with all Swift files
"""
import os
import re

# Define all Swift files to add
files_to_add = {
    'Models': [
        'Token.swift',
        'TOTPParameters.swift',
        'Vault.swift'
    ],
    'Services': [
        'Base32Decoder.swift',
        'EncryptionService.swift',
        'iCloudSyncService.swift',
        'KeychainService.swift',
        'QRCodeParser.swift',
        'TOTPGenerator.swift'
    ],
    'Utilities': [
        'ClipboardHelper.swift',
        'Logger.swift'
    ],
    'ViewModels': [
        'AddTokenViewModel.swift',
        'TokenListViewModel.swift'
    ],
    'Views': [
        'AddTokenView.swift',
        'TokenListView.swift'
    ],
    'Components': [
        'CountdownTimerView.swift',
        'EmptyStateView.swift',
        'QRCodeScannerView.swift',
        'TokenCardView.swift'
    ]
}

def generate_id(name):
    """Generate a simple identifier from filename"""
    return name.replace('.swift', '_swift').replace('.', '_')

def read_project():
    """Read the current project.pbxproj file"""
    with open('Second.xcodeproj/project.pbxproj', 'r') as f:
        return f.read()

def write_project(content):
    """Write the updated project.pbxproj file"""
    with open('Second.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)

print("Updating Xcode project with all Swift files...")
