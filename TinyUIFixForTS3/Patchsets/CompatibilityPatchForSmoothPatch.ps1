
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

$ID = 'CompatibilityPatchForSmoothPatch'
$Version = '1.0.0'
$PatchsetDefinitionSchemaVersion = 1

[PSCustomObject] @{
	FriendlyName = 'Compatibility Patch for LazyDuchess''s Smooth Patch'
	Description = 'This patch fixes scrolling through clothing in Create A Sim, when LazyDuchess''s Smooth Patch is active.'

	RecommendUsageInPresenceOfModPackageFilePathsMatching = '(?:^|/)ld_SmoothPatch'
	RecommendUsageInPresenceOfModPackageFilePathsMessage = 'Because Smooth Patch is active.'

	DuringUIScaling = @{
		PatchAssemblies = `
		{
			Param ($Self, $State)

			$AllAssemblies = $State.Assemblies.Resolver.assemblies.Values
			$SmoothPatchAssembly = $AllAssemblies.Where({$_.Name.Name -ceq 'LazyDuchess.SmoothPatch'}, 'First')[0]

			if ($Null -eq $SmoothPatchAssembly)
			{
				$State.Logger.WriteError('The "LazyDuchess.SmoothPatch" assembly could not be found.')

				return
			}

			$ClothingPerformanceType = $SmoothPatchAssembly.MainModule.GetType('LazyDuchess.SmoothPatch.ClothingPerformance')

			if ($Null -eq $ClothingPerformanceType)
			{
				return
			}

			$State.Logger.WriteInfo('SmoothPatch''s CAS clothing performance fix was detected and is being patched.')

			$ConvenientPatches = @{
				$State.Assemblies.ResourceKeysByAssembly[$SmoothPatchAssembly] = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'LazyDuchess.SmoothPatch'
					Patches = (
						,('System.Void LazyDuchess.SmoothPatch.ClothingPerformance::ItemGrid_Tick(Sims3.UI.WindowBase,Sims3.UI.UIEventArgs)', @{Doubles = 135})
					)
				}
			}

			$ConvenientlyAppliedPatches = Apply-ConvenientPatchesToAssemblies $ConvenientPatches $State.Assemblies.Resolver $State.Assemblies.AssemblyKeysByResourceKey

			@{PatchedAssemblies = $ConvenientlyAppliedPatches}
		}
	}
}

