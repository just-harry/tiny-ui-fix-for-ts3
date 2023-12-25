
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

$ID = 'CompatibilityPatchesForNRaasMods'
$Version = '1.0.0'
$PatchsetDefinitionSchemaVersion = 1

[PSCustomObject] @{
	FriendlyName = 'Compatibility Patches for NRaas Mods'
	Description = 'These patches make the UI scaling added by the Tiny UI Fix fully compatible with the NRaas Industries suite of mods.'

	RecommendUsageInPresenceOfModPackageFilePathsMatching = '(?:^|/)NRaas_'
	RecommendUsageInPresenceOfModPackageFilePathsMessage = 'Because NRaas mods are active.'

	DuringUIScaling = @{
		PatchAssemblies = `
		{
			Param ($Self, $State)

			$AllAssemblies = $State.Assemblies.Resolver.assemblies.Values
			$NRaasAssemblies = $AllAssemblies.Where{$Null -ne $_.Modules.Where({$Null -ne $_.GetType('NRaas.VersionStamp')}, 'First')[0]}
			$NRaasAssembliesByName = [TinyUIFixPSForTS3]::IndexBy($NRaasAssemblies, {$_.Name.Name})

			$State.Logger.WriteInfo("The following NRaas assemblies were found: $($NRaasAssembliesByName.Keys -join '; ').")

			$ConvenientPatches = @{}

			if ($Null -ne $NRaasAssembliesByName.NRaasMasterController)
			{
				$State.Logger.WriteInfo('NRaas Master Controller was detected and is being patched.')

				$UIKey = $TinyUIFixPSForTS3ResourceKeys.UIDLL.ToString()

				$ConvenientPatches[$State.Assemblies.ResourceKeysByAssembly[$NRaasAssembliesByName.NRaasMasterController]] = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'NRaas'
					Patches = (
						('System.Void NRaas.MasterControllerSpace.CAS.CAPUnicornEx::PopulateHornColors()', @{Floats = 21}),
						('System.Void NRaas.MasterControllerSpace.CAS.CASHairEx::SetHairTypeCategory(Sims3.UI.CAS.CASHair,Sims3.UI.CAS.CASHair/HairType)', @{Floats = 395, 421}),
						('System.Void NRaas.MasterControllerSpace.CAS.CASHairEx::HideUnusedIcons(Sims3.UI.CAS.CASHair)', @{Floats = -2, 40, 42, 210}),
						('System.Void NRaas.MasterControllerSpace.Dialogs.FamilyTreeDialog::Layout(System.Int32,System.Int32)', @{Floats = 1, 10; StaticFields = ":$UIKey/Sims3.UI.FamilyTreeDialog::X_DIST_BETWEEN_THUMBS", ":$UIKey/Sims3.UI.FamilyTreeThumb::kRegularArea.x"}),
						('Sims3.SimIFace.Rect NRaas.MasterControllerSpace.Dialogs.FamilyTreeDialog::GenericLayoutParents(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,Sims3.UI.SimTreeInfo,System.Boolean,System.Boolean)', @{StaticFields = ":$UIKey/Sims3.UI.FamilyTreeDialog::X_DIST_BETWEEN_THUMBS"}),
						('Sims3.SimIFace.Rect NRaas.MasterControllerSpace.Dialogs.FamilyTreeDialog::RecurseLayoutParents(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,System.Collections.Generic.Dictionary`2<Sims3.UI.CAS.IMiniSimDescription,Sims3.UI.SimTreeInfo>,System.Int32)', @{StaticFields = ":$UIKey/Sims3.UI.FamilyTreeDialog::X_DIST_BETWEEN_THUMBS", ":$UIKey/Sims3.UI.FamilyTreeDialog::Y_DIST_BETWEEN_THUMBS", ":$UIKey/Sims3.UI.FamilyTreeThumb::kRegularArea.x", ":$UIKey/Sims3.UI.FamilyTreeThumb::kRegularArea.y"}),
						('Sims3.SimIFace.Rect NRaas.MasterControllerSpace.Dialogs.FamilyTreeDialog::RecurseLayoutChildren(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,Sims3.UI.SimTreeInfo,System.Int32,System.Boolean,System.Boolean)', @{StaticFields = ":$UIKey/Sims3.UI.FamilyTreeDialog::X_DIST_BETWEEN_THUMBS", ":$UIKey/Sims3.UI.FamilyTreeDialog::Y_DIST_BETWEEN_THUMBS", ":$UIKey/Sims3.UI.FamilyTreeThumb::kRegularArea.x"}),
						('System.Void NRaas.MasterControllerSpace.Dialogs.FamilyTreeDialog::RefreshTree(Sims3.UI.CAS.IMiniSimDescription)', @{Floats = 15; Integers = 5; StaticFields = ":$UIKey/Sims3.UI.FamilyTreeDialog::BUFFER", ":$UIKey/Sims3.UI.FamilyTreeDialog::SCROLL_BUFFER", ":$UIKey/Sims3.UI.FamilyTreeDialog::MIN_WIDTH", ":$UIKey/Sims3.UI.FamilyTreeDialog::MIN_HEIGHT"}),
						('System.Void NRaas.MasterControllerSpace.Sims.CASBase::OnShowUI(System.Boolean)', @{Floats = 2, 58, 109, 341, 352, 387, 397})
					)
				}
			}

			if ($Null -ne $NRaasAssembliesByName.NRaasPortraitPanel)
			{
				$State.Logger.WriteInfo('NRaas Portrait Panel was detected and is being patched.')

				$ConvenientPatches[$State.Assemblies.ResourceKeysByAssembly[$NRaasAssembliesByName.NRaasPortraitPanel]] = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'NRaas'
					Patches = (
						,('System.Void NRaas.PortraitPanelSpace.Dialogs.SkewerEx::PopulateSkewers(System.Boolean)', @{Floats = 60, 118})
					)
				}
			}

			foreach ($NRaasAssembly in $NRaasAssemblies)
			{
				$ResourceKey = $State.Assemblies.ResourceKeysByAssembly[$NRaasAssembly]
				$ConvenientPatch = $ConvenientPatches[$ResourceKey]

				if ($Null -eq $ConvenientPatch)
				{
					$ConvenientPatch = @{
						TinyUIFixForTS3IntegrationTypeNamespace = 'NRaas'
						Patches = @()
					}
					$ConvenientPatches[$ResourceKey] = $ConvenientPatch
				}

				$ConvenientPatch.Patches += (
					('System.Void NRaas.CommonSpace.Dialogs.ObjectPickerDialogEx::.ctor(System.String,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>,System.Int32,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/RowInfo>)', @{Floats = 200; Optional = $True}),
					('System.Void NRaas.CommonSpace.Dialogs.ObjectPickerDialogEx::ResizeWindow(System.Boolean)', @{Floats = 20, 50; Optional = $True})
				)
			}

			$PatchCount = ($ConvenientPatches.Values.ForEach{$_.Patches.Count} | Measure-Object -Sum).Sum
			$State.Logger.WriteInfo("Applying $PatchCount patch$(if ($PatchCount -ne 1) {'es'}) across the NRaas assemblies.")

			$ConvenientlyAppliedPatches = Apply-ConvenientPatchesToAssemblies $ConvenientPatches $State.Assemblies.Resolver $State.Assemblies.AssemblyKeysByResourceKey

			@{PatchedAssemblies = $ConvenientlyAppliedPatches}
		}
	}
}

