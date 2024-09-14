
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2024-2024.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

$ID = 'SliderEnhancements'
$Version = '1.0.0'
$PatchsetDefinitionSchemaVersion = 2


[PSCustomObject] @{
	FriendlyName = 'Slider Enhancements'
	Description = @'
This patchset enhances the functionality of sliders in many various ways, mainly for convenience in Create a Sim.
<details>
	<summary>Details of the enhancements</summary>
	<ul>
		<li>Right-clicking a slider will bring up a dialog that allows a numeric value to be typed in for the slider.</li>
		<li>
			When the mouse is over a slider, keyboard keys can be used to change its value, those keys are:
			<ul>
				<li><kbd>A</kbd> to decrement the slider by 1.</li>
				<li><kbd>D</kbd> to increment the slider by 1.</li>
				<li><kbd>S</kbd> to decrement the slider by 8.</li>
				<li><kbd>W</kbd> to increment the slider by 8.</li>
				<li><kbd>F</kbd> to decrement the slider by 32.</li>
				<li><kbd>R</kbd> to increment the slider by 32.</li>
				<li><kbd>Shift</kbd>+<kbd>A</kbd> to decrement the slider by 64.</li>
				<li><kbd>Shift</kbd>+<kbd>D</kbd> to increment the slider by 64.</li>
				<li><kbd>Shift</kbd>+<kbd>S</kbd> to decrement the slider by 128.</li>
				<li><kbd>Shift</kbd>+<kbd>W</kbd> to increment the slider by 128.</li>
				<li><kbd>Shift</kbd>+<kbd>F</kbd> to decrement the slider by 256.</li>
				<li><kbd>Shift</kbd>+<kbd>R</kbd> to increment the slider by 256.</li>
			</ul>
			In Create a Sim, this functionality is extended to apply to the last slider
			that the mouse was over—making it possible to change a slider while adjusting the camera.
		</li>
		<li>
			<p>
				There are ten save-slots available for slider values, each corresponding to a number key on the keyboard.
				<br>
				Pressing <kbd>Alt</kbd>+<kbd>&lt;a number key&gt;</kbd> will save the current value of a slider to the corresponding save slot.
				<br>
				Pressing <kbd>&lt;a number key&gt;</kbd> will load a saved value from the corresponding save slot.
			</p>
			<p>
				The default values of the save-slots, from zero-to-ten, are: 0; -256; -128; 0; 128; 256; -64; 64; -32; 32.
				<br>
				<kbd>Shift</kbd>+<kbd>0</kbd> will reset all save-slots to their default value.
			</p>
			<p>The behaviour for whether or not a slider is focussed is the same as for the keyboard keys for decrementing and incrementing a slider.</p>
		</li>
		<li>In Create a Sim, slider values can be set beyond their usual limits via this functionality.</li>
	</ul>
</details>
'@

	DuringUIScaling = @{
		ReplaceResources = `
		{
			$DataPath = Join-Path $State.Paths.Root Data

			$SliderEnhancementTriggersStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes((Join-Path $DataPath SliderEnhancementTriggers.triggers)))

			$SliderEnhancementTriggers = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::_XMLTypeID)
			$SliderEnhancementTriggersStream.CopyTo($SliderEnhancementTriggers.Stream)
			$SliderEnhancementTriggers.Stream.Position = 0

			$State.Logger.WriteInfo('Adding the Slider Enhancement resources.')

			@{
				Resources = @(
					@{Resource = $SliderEnhancementTriggers; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3SliderEnhancementTriggers}
				)
			}
		}

		PatchAssemblies = `
		{
			Param ($Self, $State)

			$State.Logger.WriteInfo('Enhancing sliders.')

			$UI = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.UIDLL])
			$TinyUIFixForTS3CoreBridge = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3CoreBridge])
			$System = $State.Assemblies.Resolver.Resolve([ValueTuple[String, Version]]::new('System', [Version]::new(2, 0, 0, 0)))
			$mscorlib = $State.Assemblies.Resolver.Resolve([ValueTuple[String, Version]]::new('mscorlib', [Version]::new(2, 0, 0, 0)))
			$TinyUIFixForTS3DLL = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3DLL])

			$ScaledSliderMimicType = $TinyUIFixForTS3DLL.MainModule.GetType('TinyUIFixForTS3.UI.ScaledSliderMimic')

			$UIMouseEventArgsType = $UI.MainModule.GetType('Sims3.UI.UIMouseEventArgs')
			$MouseKeysType = $UI.MainModule.GetType('Sims3.UI.MouseKeys')

			$UIMouseEventArgsMouseKey = Find-InstanceProperty $UIMouseEventArgsType MouseKey
			$kMouseRight = Find-StaticField $MouseKeysType kMouseRight

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType AttachEventsToThumb) `
			{
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType AttachEnhancedEventsToThumb)))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType DetachEventsFromThumb) `
			{
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType DetachEnhancedEventsFromThumb)))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType AttachEventsToThumbContainer) `
			{
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType AttachEnhancedEventsToThumbContainer)))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType DetachEventsFromThumbContainer) `
			{
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($Returns[0], [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType DetachEnhancedEventsFromThumbContainer)))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType HandleThumbMouseDown Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs) `
			{
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $TinyUIFixForTS3DLL.MainModule.Import($UIMouseEventArgsMouseKey.GetMethod)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($kMouseRight.Constant)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bne_Un, $StartOfIL))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType HandleThumbContainerMouseDown Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs) `
			{
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $TinyUIFixForTS3DLL.MainModule.Import($UIMouseEventArgsMouseKey.GetMethod)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($kMouseRight.Constant)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bne_Un, $StartOfIL))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType HandleThumbMouseUp Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs) `
			{
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $TinyUIFixForTS3DLL.MainModule.Import($UIMouseEventArgsMouseKey.GetMethod)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($kMouseRight.Constant)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bne_Un, $StartOfIL))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_1))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType HandleEnhancedThumbMouseUp Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))
			}

			Edit-MethodBody (Find-InstanceMethod $ScaledSliderMimicType HandleThumbContainerMouseUp Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs) `
			{
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $TinyUIFixForTS3DLL.MainModule.Import($UIMouseEventArgsMouseKey.GetMethod)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($kMouseRight.Constant)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bne_Un, $StartOfIL))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_1))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_2))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, (Find-InstanceMethod $ScaledSliderMimicType HandleEnhancedThumbContainerMouseUp Sims3.UI.WindowBase, Sims3.UI.UIMouseEventArgs)))
				$IL.InsertBefore($StartOfIL, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret))
			}

			@{PatchedAssemblies = @(@{ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3DLL})}
		}
	}
}

