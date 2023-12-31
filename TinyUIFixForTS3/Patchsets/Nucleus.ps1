
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

$ID = 'Nucleus'
$Version = '1.0.0'
$PatchsetDefinitionSchemaVersion = 1


[PSCustomObject] @{
	FriendlyName = 'Nucleus of Tiny UI Fix for The Sims 3'
	Description = 'The nucleus of Tiny UI Fix for The Sims 3. It is required for the generated package to function.'

	EffectiveUIScale = [Float] 1
	EffectiveTextScale = [Float] 1

	MakeDefaultConfiguration = `
	{
		Param ($Self)

		@{UIScale = [Float] 1}
	}

	SettleStateBeforePatchsetsAreApplied = `
	{
		Param ($Self, $State)

		$State.Configuration.Nucleus.UIScale = if ($Null -eq $State.Configuration.Nucleus.UIScale)
		{
			[Float] 1
		}
		else
		{
			try
			{
				[Float] $State.Configuration.Nucleus.UIScale
			}
			catch
			{
				$State.Logger.WriteWarning("The value of `"$($State.Configuration.Nucleus.UIScale)`" for Nucleus.UIScale couldn't be coerced to a float, so it's being defaulted to a value of 1.")

				[Float] 1
			}
		}

		$State.Configuration.Nucleus.TextScale = if (
			    $Null -eq $State.Configuration.Nucleus.TextScale `
			-or ($State.Configuration.Nucleus.TextScale -is [String] -and [String]::IsNullOrWhiteSpace($State.Configuration.Nucleus.TextScale))
		)
		{
			$Null
		}
		else
		{
			try
			{
				[Float] $State.Configuration.Nucleus.TextScale
			}
			catch
			{
				$State.Logger.WriteWarning("The value of `"$($State.Configuration.Nucleus.TextScale)`" for Nucleus.TextScale couldn't be coerced to a float, so it's being defaulted to the value of Nucleus.UIScale.")

				$State.Configuration.Nucleus.UIScale
			}
		}

		$Self.EffectiveUIScale = $State.Configuration.Nucleus.UIScale
		$Self.EffectiveTextScale = if ($Null -ne $State.Configuration.Nucleus.TextScale) {$State.Configuration.Nucleus.TextScale} else {$State.Configuration.Nucleus.UIScale}
	}

	DuringUIScaling = @{
		ReplaceResources = `
		{
			Param ($Self, $State)

			$DataPath = Join-Path $State.Paths.Root Data
			$UIScale = $State.Configuration.Nucleus.UIScale

			$TinyUIFixForTS3XMLStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes((Join-Path $DataPath TinyUIFixForTS3.xml)))
			$TinyUIFixForTS3DLLStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes((Join-Path $DataPath TinyUIFixForTS3.dll)))
			$TinyUIFixForTS3CoreBridgeStream = [IO.MemoryStream]::new([IO.File]::ReadAllBytes((Join-Path $DataPath TinyUIFixForTS3CoreBridge.dll)))

			$TinyUIFixForTS3 = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($TinyUIFixForTS3DLLStream)

			Apply-PatchToTinyUIFixForTS3Assembly $TinyUIFixForTS3 $UIScale

			$TinyUIFixForTS3.Write()

			$TinyUIFixForTS3DLLStream.Position = 0
			$TinyUIFixForTS3DLL = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::S3SATypeID)
			$TinyUIFixForTS3DLL.Assembly = [IO.BinaryReader]::new($TinyUIFixForTS3DLLStream)

			$TinyUIFixForTS3CoreBridgeStream.Position = 0
			$TinyUIFixForTS3CoreBridge = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::S3SATypeID)
			$TinyUIFixForTS3CoreBridge.Assembly = [IO.BinaryReader]::new($TinyUIFixForTS3CoreBridgeStream)

			$TinyUIFixForTS3XML = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::_XMLTypeID)
			$TinyUIFixForTS3XMLStream.CopyTo($TinyUIFixForTS3XML.Stream)
			$TinyUIFixForTS3XML.Stream.Position = 0

			$XMLWritingSettings = [Xml.XmlWriterSettings]::new()
			$XMLWritingSettings.Indent = $True
			$XMLWritingSettings.IndentChars = "`t"
			$XMLWritingSettings.NewLineChars = "`r`n"
			$XMLWritingSettings.Encoding = $UTF8

			$LayoutResource = `
			{
				Param ($Path)

				$Layout = [Xml.XmlDocument]::new()
				$Layout.Load((Join-Path $DataPath $Path))
				[TinyUIFixForTS3Patcher.LayoutScaler]::ScaleLayoutBy($Layout, $UIScale, [TinyUIFixForTS3Patcher.LayoutScaler+ExtraScaler[]] @()) > $Null
				$Resource = [s3pi.WrapperDealer.WrapperDealer]::CreateNewResource(1, '0x{0:X08}' -f [TinyUIFixPSForTS3]::LAYOTypeID)

				[TinyUIFixPSForTS3]::UseDisposable(
					{[Xml.XmlWriter]::Create($Resource.Stream, $XMLWritingSettings)},
					{Param ($Writer) $Layout.Save($Writer)}
				) > $Null

				$Resource.Stream.Position = 0
				$Resource
			}

			$State.Logger.WriteInfo('Adding the Tiny UI Fix resources.')

			@{
				Resources = @(
					@{Resource = $TinyUIFixForTS3DLL; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3DLL}
					@{Resource = $TinyUIFixForTS3CoreBridge; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3CoreBridge}
					@{Resource = $TinyUIFixForTS3XML; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3XML}
					@{Resource = & $LayoutResource ScaledVerticalScrollbarMimic.xml; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledVerticalScrollbarMimic}
					@{Resource = & $LayoutResource ScaledHorizontalScrollbarMimic.xml; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledHorizontalScrollbarMimic}
					@{Resource = & $LayoutResource ScaledVerticalSliderMimic.xml; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledVerticalSliderMimic}
					@{Resource = & $LayoutResource ScaledHorizontalSliderMimic.xml; ResourceKey = $TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3ScaledHorizontalSliderMimic}
				)
			}
		}

		PatchAssemblies = `
		{
			Param ($Self, $State)

			$UI = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.UIDLL])
			$TinyUIFixForTS3CoreBridge = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.TinyUIFixForTS3CoreBridge])
			$System = $State.Assemblies.Resolver.Resolve([ValueTuple[String, Version]]::new('System', [Version]::new(2, 0, 0, 0)))
			$mscorlib = $State.Assemblies.Resolver.Resolve([ValueTuple[String, Version]]::new('mscorlib', [Version]::new(2, 0, 0, 0)))

			$State.Logger.WriteInfo('Adding event-registration events to UIManager in UI.dll.')

			$UIManagerType = $UI.MainModule.GetType('Sims3.UI.UIManager')
			$WindowBaseType = $UI.MainModule.GetType('Sims3.UI.WindowBase')
			$mEventRegistry = Find-StaticField $UIManagerType mEventRegistry

			$WindowBaseWinHandle = Find-InstanceProperty $WindowBaseType WinHandle


			$TinyUIFixForTS3UIEventRegistrationEventsType = [Mono.Cecil.TypeDefinition]::new(
				'Sims3.UI',
				'TinyUIFixForTS3UIEventRegistrationEvents',
				[Mono.Cecil.TypeAttributes]::Public -bor [Mono.Cecil.TypeAttributes]::Abstract -bor [Mono.Cecil.TypeAttributes]::Sealed -bor [Mono.Cecil.TypeAttributes]::BeforeFieldInit,
				$UI.MainModule.TypeSystem.Object
			)
			$UI.MainModule.Types.Add($TinyUIFixForTS3UIEventRegistrationEventsType)

			$TinyUIFixForTS3UIEventRegistrationChangeEventHandlerTypeDefinition = $TinyUIFixForTS3CoreBridge.MainModule.GetType('TinyUIFixForTS3CoreBridge.UIEventRegistrationChangeEventHandler')
			$TinyUIFixForTS3UIEventRegistrationChangeEventHandlerType = $UI.MainModule.Import($TinyUIFixForTS3UIEventRegistrationChangeEventHandlerTypeDefinition)
			$TinyUIFixForTS3UIEventRegistrationChangeEventHandlerInvoke = $UI.MainModule.Import((Find-InstanceMethod $TinyUIFixForTS3UIEventRegistrationChangeEventHandlerTypeDefinition Invoke System.UInt32, System.UInt32, System.UInt32))

			$ExceptionTypeDefinition = $mscorlib.MainModule.GetType('System.Exception')
			$DictionaryTypeDefinition = $mscorlib.MainModule.GetType('System.Collections.Generic.Dictionary`2')
			$ListTypeDefinition = $mscorlib.MainModule.GetType('System.Collections.Generic.List`1')
			$ExceptionType = $UI.MainModule.Import($ExceptionTypeDefinition)
			$ListType = $UI.MainModule.Import($ListTypeDefinition)
			$DictionaryType = $UI.MainModule.Import($DictionaryTypeDefinition)

			${List<UInt32>Type} = [Mono.Cecil.GenericInstanceType]::new($ListType)
			${List<UInt32>Type}.GenericArguments.Add($UI.MainModule.TypeSystem.UInt32)
			${List<EventRegistrationChangeEventHandler>Type} = [Mono.Cecil.GenericInstanceType]::new($ListType)
			${List<EventRegistrationChangeEventHandler>Type}.GenericArguments.Add($TinyUIFixForTS3UIEventRegistrationChangeEventHandlerType)
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type} = [Mono.Cecil.GenericInstanceType]::new($DictionaryType)
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}.GenericArguments.Add($UI.MainModule.TypeSystem.UInt32)
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}.GenericArguments.Add(${List<EventRegistrationChangeEventHandler>Type})

			${List<UInt32>CtorWithCapacity} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition .ctor System.Int32))
			${List<UInt32>CtorWithCapacity}.DeclaringType = ${List<UInt32>Type}
			${List<UInt32>CountGetter} = $UI.MainModule.Import((Find-InstanceProperty $ListTypeDefinition Count).GetMethod)
			${List<UInt32>CountGetter}.DeclaringType = ${List<UInt32>Type}
			${List<UInt32>ItemGetter} = $UI.MainModule.Import((Find-InstanceProperty $ListTypeDefinition Item).GetMethod)
			${List<UInt32>ItemGetter}.DeclaringType = ${List<UInt32>Type}
			${List<UInt32>Contains} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Contains T))
			${List<UInt32>Contains}.DeclaringType = ${List<UInt32>Type}
			${List<UInt32>Add} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Add T))
			${List<UInt32>Add}.DeclaringType = ${List<UInt32>Type}
			${List<UInt32>Remove} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Remove T))
			${List<UInt32>Remove}.DeclaringType = ${List<UInt32>Type}
			${List<EventRegistrationChangeEventHandler>CtorWithCapacity} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition .ctor System.Int32))
			${List<EventRegistrationChangeEventHandler>CtorWithCapacity}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${List<EventRegistrationChangeEventHandler>CountGetter} = $UI.MainModule.Import((Find-InstanceProperty $ListTypeDefinition Count).GetMethod)
			${List<EventRegistrationChangeEventHandler>CountGetter}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${List<EventRegistrationChangeEventHandler>ItemGetter} = $UI.MainModule.Import((Find-InstanceProperty $ListTypeDefinition Item).GetMethod)
			${List<EventRegistrationChangeEventHandler>ItemGetter}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${List<EventRegistrationChangeEventHandler>Contains} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Contains T))
			${List<EventRegistrationChangeEventHandler>Contains}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${List<EventRegistrationChangeEventHandler>Add} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Add T))
			${List<EventRegistrationChangeEventHandler>Add}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${List<EventRegistrationChangeEventHandler>Remove} = $UI.MainModule.Import((Find-InstanceMethod $ListTypeDefinition Remove T))
			${List<EventRegistrationChangeEventHandler>Remove}.DeclaringType = ${List<EventRegistrationChangeEventHandler>Type}
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Ctor} = $UI.MainModule.Import((Find-InstanceMethod $DictionaryTypeDefinition .ctor))
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Ctor}.DeclaringType = ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>TryGetValue} = $UI.MainModule.Import((Find-InstanceMethod $DictionaryTypeDefinition TryGetValue TKey, 'TValue&'))
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>TryGetValue}.DeclaringType = ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>ItemSetter} = $UI.MainModule.Import((Find-InstanceProperty $DictionaryTypeDefinition Item).SetMethod)
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>ItemSetter}.DeclaringType = ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Remove} = $UI.MainModule.Import((Find-InstanceMethod $DictionaryTypeDefinition Remove TKey))
			${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Remove}.DeclaringType = ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}

			$TinyUIFixForTS3UIEventRegistrationEventsRegistry = [Mono.Cecil.FieldDefinition]::new(
				'eventRegistrationEventRegistry',
				[Mono.Cecil.FieldAttributes]::Public.value__ -bor [Mono.Cecil.FieldAttributes]::Static,
				${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Type}
			)
			$TinyUIFixForTS3UIEventRegistrationEventsType.Fields.Add($TinyUIFixForTS3UIEventRegistrationEventsRegistry)

			$TinyUIFixForTS3UIEventRegistrationEventsCCtor = [Mono.Cecil.MethodDefinition]::new(
				'.cctor',
				[Mono.Cecil.MethodAttributes]::Private.value__ -bor [Mono.Cecil.MethodAttributes]::Static -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
				$UI.MainModule.TypeSystem.Void
			)
			Edit-MethodBody $TinyUIFixForTS3UIEventRegistrationEventsCCtor `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Ctor})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}
			$TinyUIFixForTS3UIEventRegistrationEventsType.Methods.Add($TinyUIFixForTS3UIEventRegistrationEventsCCtor)

			$TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers = [Mono.Cecil.MethodDefinition]::new(
				'TriggerEventRegistrationChangeEventHandlers',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))
			$TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))
			$TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))

			Edit-MethodBody $TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers `
			{
				$ListLocal = Add-VariableToMethod $Method ${List<EventRegistrationChangeEventHandler>Type}
				$CountLocal = Add-VariableToMethod $Method $UI.MainModule.TypeSystem.Int32
				$IndexLocal = Add-VariableToMethod $Method $UI.MainModule.TypeSystem.Int32

				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloca, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>TryGetValue})
				$IL.Append(($If = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Dup)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $IndexLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>CountGetter})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Dup)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $CountLocal)
				$IL.Append(($WhileInBounds = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bge, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $IndexLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>ItemGetter})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_2)
				$IL.Append(($EventHandlerCall = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $TinyUIFixForTS3UIEventRegistrationChangeEventHandlerInvoke)))
				$IL.Append(($EventHandlerCallLeave = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Leave, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Append(($EventHandlerCallCatchLeave = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Leave, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Append(($AfterEventHandlerCall = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $IndexLocal)))
				$EventHandlerCallCatchLeave.Operand = $EventHandlerCallLeave.Operand = $AfterEventHandlerCall
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Add)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Dup)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $IndexLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::LdLoc, $CountLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Br, $WhileInBounds)
				$IL.Append(($Ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)))
				$WhileInBounds.Operand = $If.Operand = $Ret

				$EventHandlerExceptionSwallower = [Mono.Cecil.Cil.ExceptionHandler]::new([Mono.Cecil.Cil.ExceptionHandlerType]::Catch)
				$EventHandlerExceptionSwallower.TryStart = $EventHandlerCall
				$EventHandlerExceptionSwallower.TryEnd = $EventHandlerCallLeave.Next
				$EventHandlerExceptionSwallower.HandlerStart = $EventHandlerCallCatchLeave
				$EventHandlerExceptionSwallower.HandlerEnd = $EventHandlerExceptionSwallower.HandlerStart.Next
				$EventHandlerExceptionSwallower.CatchType = $ExceptionType

				$Method.Body.ExceptionHandlers.Add($EventHandlerExceptionSwallower)
			}

			$TinyUIFixForTS3UIEventRegistrationEventsType.Methods.Add($TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers)


			$TinyUIFixForTS3UIEventRegistrationEventsRegisterEventRegistrationChangeEventHandler = [Mono.Cecil.MethodDefinition]::new(
				'RegisterEventRegistrationChangeEventHandler',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3UIEventRegistrationEventsRegisterEventRegistrationChangeEventHandler.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))
			$TinyUIFixForTS3UIEventRegistrationEventsRegisterEventRegistrationChangeEventHandler.Parameters.Add((New-ParameterDefinition $TinyUIFixForTS3UIEventRegistrationChangeEventHandlerType $UI.MainModule))

			Edit-MethodBody $TinyUIFixForTS3UIEventRegistrationEventsRegisterEventRegistrationChangeEventHandler `
			{
				$ListLocal = Add-VariableToMethod $Method ${List<EventRegistrationChangeEventHandler>Type}

				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloca, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>TryGetValue})
				$IL.Append(($IfTryGetValue = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>Contains})
				$IL.Append(($IfNotContains = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brtrue, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>Add})
				$IL.Append(($Ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)))
				$IfNotContains.Operand = $Ret
				$IL.Append(($IfTryGetValue.Operand = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, ${List<EventRegistrationChangeEventHandler>CtorWithCapacity})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>ItemSetter})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>Add})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}

			$TinyUIFixForTS3UIEventRegistrationEventsType.Methods.Add($TinyUIFixForTS3UIEventRegistrationEventsRegisterEventRegistrationChangeEventHandler)


			$TinyUIFixForTS3UIEventRegistrationEventsDeregisterEventRegistrationChangeEventHandler = [Mono.Cecil.MethodDefinition]::new(
				'DeregisterEventRegistrationChangeEventHandler',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3UIEventRegistrationEventsDeregisterEventRegistrationChangeEventHandler.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))
			$TinyUIFixForTS3UIEventRegistrationEventsDeregisterEventRegistrationChangeEventHandler.Parameters.Add((New-ParameterDefinition $TinyUIFixForTS3UIEventRegistrationChangeEventHandlerType $UI.MainModule))

			Edit-MethodBody $TinyUIFixForTS3UIEventRegistrationEventsDeregisterEventRegistrationChangeEventHandler `
			{
				$ListLocal = Add-VariableToMethod $Method ${List<EventRegistrationChangeEventHandler>Type}

				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloca, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>TryGetValue})
				$IL.Append(($IfTryGetValue = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Brfalse, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $ListLocal)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Dup)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_1)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>Remove})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Pop)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${List<EventRegistrationChangeEventHandler>CountGetter})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)
				$IL.Append(($IfEmpty = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Bne_Un, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Nop))))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3UIEventRegistrationEventsRegistry)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, ${Dictionary<UInt32, List<EventRegistrationChangeEventHandler>>Remove})
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Pop)
				$IL.Append(($Ret = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ret)))
				$IfEmpty.Operand = $IfTryGetValue.Operand = $Ret
			}

			$TinyUIFixForTS3UIEventRegistrationEventsType.Methods.Add($TinyUIFixForTS3UIEventRegistrationEventsDeregisterEventRegistrationChangeEventHandler)


			$PatchEventRegistrationMethod = `
			{
				Param ($Method, $TargetFieldName, $TargetName, $TargetStackDepth, [Mono.Cecil.Cil.OpCode] $LoadEventType, [Mono.Cecil.Cil.OpCode] $LoadEventRegistrationChangeType)

				Edit-MethodBody $Method `
				{
					:ForEachInstruction do
					{
						if (
							     $Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldsfld `
							-and $Instruction.Operand.Name -ceq $TargetFieldName `
							-and $Instruction.Operand.DeclaringType.Name -ceq 'UIManager' `
							-and $Instruction.Operand.DeclaringType.Namespace -ceq 'Sims3.UI'
						)
						{
							$StackDepth = 0

							while ($Instruction = $Instruction.Next)
							{
								$StackDepthDelta = 0

								if ([TinyUIFixForTS3Patcher.AssemblyScaling+OpCodeInspection]::StaticallyKnownStackDepthChangeEffectedBy($Instruction, [Ref] $StackDepthDelta))
								{
									if ($Instruction.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Call)
									{
										if ($StackDepth -eq $TargetStackDepth -and $Instruction.Operand.Name -ceq $TargetName)
										{
											$AfterEventRegistrationChange = $Instruction.Next

											@(
												[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldarg_0)
												[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $WindowBaseWinHandle.GetMethod)
												[Mono.Cecil.Cil.Instruction]::Create($LoadEventType)
												[Mono.Cecil.Cil.Instruction]::Create($LoadEventRegistrationChangeType)
												[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $TinyUIFixForTS3UIEventRegistrationEventsTriggerEventRegistrationChangeEventHandlers)
											).ForEach{$IL.InsertBefore($AfterEventRegistrationChange, $_)}

											break
										}
									}

									$StackDepth += $StackDepthDelta

									if ($StackDepth -lt 0)
									{
										continue ForEachInstruction
									}
								}
								else
								{
									continue ForEachInstruction
								}
							}
						}
					}
					while ($Instruction = $Instruction.Next)
				}
			}

			$DeRegisterAllEvents = Find-StaticMethod $UIManagerType DeRegisterAllEvents Sims3.UI.WindowBase
			$DeRegisterEvent = Find-StaticMethod $UIManagerType DeRegisterEvent Sims3.UI.WindowBase, System.UInt32, 'Sims3.UI.UIEventHandler`1<ArgsType>'
			$RegisterEvent = Find-StaticMethod $UIManagerType RegisterEvent Sims3.UI.WindowBase, System.UInt32, 'Sims3.UI.UIEventHandler`1<ArgsType>'

			& $PatchEventRegistrationMethod $DeRegisterAllEvents mEventRegistry Remove 1 ([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0) ([Mono.Cecil.Cil.OpCodes]::Ldc_I4_2)
			& $PatchEventRegistrationMethod $DeRegisterEvent mEventRegistry Remove 1 ([Mono.Cecil.Cil.OpCodes]::Ldarg_1) ([Mono.Cecil.Cil.OpCodes]::Ldc_I4_1)
			& $PatchEventRegistrationMethod $RegisterEvent gUIMgr RegisterEvent 2 ([Mono.Cecil.Cil.OpCodes]::Ldarg_1) ([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)


			$State.Logger.WriteInfo('Adding Tiny UI Fix hooks to UI.dll.')

			$LayoutType = $UI.MainModule.GetType('Sims3.UI.Layout')
			$UICategoryType = $UI.MainModule.GetType('Sims3.UI.UICategory')
			$WindowBaseType = $UI.MainModule.GetType('Sims3.UI.WindowBase')
			$DialogType = $UI.MainModule.GetType('Sims3.UI.Dialog')
			$ModalDialogType = $UI.MainModule.GetType('Sims3.UI.ModalDialog')
			$ScrollbarType = $UI.MainModule.GetType('Sims3.UI.Scrollbar')
			$SliderType = $UI.MainModule.GetType('Sims3.UI.Slider')
			$TextEditType = $UI.MainModule.GetType('Sims3.UI.TextEdit')

			$TinyUIFixForTS3HooksType = [Mono.Cecil.TypeDefinition]::new(
				'Sims3.UI',
				'TinyUIFixForTS3Hooks',
				[Mono.Cecil.TypeAttributes]::Public -bor [Mono.Cecil.TypeAttributes]::Abstract -bor [Mono.Cecil.TypeAttributes]::Sealed -bor [Mono.Cecil.TypeAttributes]::BeforeFieldInit,
				$UI.MainModule.TypeSystem.Object
			)

			$AddHookField = `
			{
				Param ($Name, $DelegateName, $Type)

				$HookType = New-DelegateTypeDefinition $UI.MainModule $mscorlib $Null $DelegateName ([Mono.Cecil.TypeAttributes]::NestedPublic) $UI.MainModule.TypeSystem.Void $Type

				$TinyUIFixForTS3HooksType.NestedTypes.Add($HookType)

				$HookField = [Mono.Cecil.FieldDefinition]::new($Name, [Mono.Cecil.FieldAttributes]::Public.value__ -bor [Mono.Cecil.FieldAttributes]::Static, $HookType)
				$TinyUIFixForTS3HooksType.Fields.Add($HookField)

				$HookField
				$HookType
				Find-InstanceMethod $HookType Invoke $Type.FullName
			}

			$TinyUIFixForTS3HooksReactToRetrievedWindowInstanceAddedToCache, $ReactToRetrievedWindowInstanceAddedToCacheType, $ReactToRetrievedWindowInstanceAddedToCacheInvoke = & $AddHookField reactToRetrievedWindowInstanceAddedToCache ReactToRetrievedWindowInstanceAddedToCache @(,@($WindowBaseType, 'window'))
			$TinyUIFixForTS3HooksReactToInitialisationOfMainMenu, $ReactToInitialisationOfMainMenuType, $ReactToInitialisationOfMainMenuInvoke = & $AddHookField reactToInitialisationOfMainMenu ReactToInitialisationOfMainMenu

			$TinyUIFixForTS3HooksCCtor = [Mono.Cecil.MethodDefinition]::new(
				'.cctor',
				[Mono.Cecil.MethodAttributes]::Private.value__ -bor [Mono.Cecil.MethodAttributes]::Static -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
				$UI.MainModule.TypeSystem.Void
			)

			$TinyUIFixForTS3HooksStubForWindowTakingHook = [Mono.Cecil.MethodDefinition]::new(
				'StubForWindowTakingHook',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3HooksStubForWindowTakingHook.Parameters.Add((New-ParameterDefinition $WindowBaseType, 'window' $UI.MainModule))
			Edit-MethodBody $TinyUIFixForTS3HooksStubForWindowTakingHook `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}
			$TinyUIFixForTS3HooksType.Methods.Add($TinyUIFixForTS3HooksStubForWindowTakingHook)

			$TinyUIFixForTS3HooksStubForHookWithoutParameters = [Mono.Cecil.MethodDefinition]::new(
				'StubForHookWithoutParameters',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			Edit-MethodBody $TinyUIFixForTS3HooksStubForHookWithoutParameters `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}
			$TinyUIFixForTS3HooksType.Methods.Add($TinyUIFixForTS3HooksStubForHookWithoutParameters)

			Edit-MethodBody $TinyUIFixForTS3HooksCCtor `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldnull)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldftn, $TinyUIFixForTS3HooksStubForWindowTakingHook)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, (Find-InstanceMethod $ReactToRetrievedWindowInstanceAddedToCacheType .ctor System.Object, System.IntPtr))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, $TinyUIFixForTS3HooksReactToRetrievedWindowInstanceAddedToCache)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldnull)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldftn, $TinyUIFixForTS3HooksStubForHookWithoutParameters)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, (Find-InstanceMethod $ReactToInitialisationOfMainMenuType .ctor System.Object, System.IntPtr))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, $TinyUIFixForTS3HooksReactToInitialisationOfMainMenu)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}

			$TinyUIFixForTS3HooksType.Methods.Add($TinyUIFixForTS3HooksCCtor)

			$UI.MainModule.Types.Add($TinyUIFixForTS3HooksType)


			$TinyUIFixForTS3InitialisationType = [Mono.Cecil.TypeDefinition]::new(
				'Sims3.UI',
				'TinyUIFixForTS3Initialisation',
				[Mono.Cecil.TypeAttributes]::Public -bor [Mono.Cecil.TypeAttributes]::Abstract -bor [Mono.Cecil.TypeAttributes]::Sealed -bor [Mono.Cecil.TypeAttributes]::BeforeFieldInit,
				$UI.MainModule.TypeSystem.Object
			)

			$TinyUIFixForTS3InitialisationCCtor = [Mono.Cecil.MethodDefinition]::new(
				'.cctor',
				[Mono.Cecil.MethodAttributes]::Private.value__ -bor [Mono.Cecil.MethodAttributes]::Static -bor [Mono.Cecil.MethodAttributes]::HideBySig -bor [Mono.Cecil.MethodAttributes]::SpecialName -bor [Mono.Cecil.MethodAttributes]::RTSpecialName,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3InitialisationType.Methods.Add($TinyUIFixForTS3InitialisationCCtor)

			$RegisterLayoutWinProcByControlIDChainType = New-DelegateTypeDefinition $UI.MainModule $mscorlib $Null registerLayoutWinProcByControlIDChain ([Mono.Cecil.TypeAttributes]::NestedPublic) $UI.MainModule.TypeSystem.Void ([Mono.Cecil.ByReferenceType]::new($UI.MainModule.TypeSystem.Object)), $UI.MainModule.TypeSystem.UInt32, $UI.MainModule.TypeSystem.Byte, $UI.MainModule.TypeSystem.Single, $UI.MainModule.TypeSystem.Single
			$RegisterLayoutWinProcByControlIDChainInvoke = Find-InstanceMethod $RegisterLayoutWinProcByControlIDChainType Invoke 'System.Object&', System.UInt32, System.Byte, System.Single, System.Single

			$TinyUIFixForTS3InitialisationType.NestedTypes.Add($RegisterLayoutWinProcByControlIDChainType)

			$TinyUIFixForTS3InitialisationRegisterLayoutWinProcByControlIDChain = [Mono.Cecil.FieldDefinition]::new(
				'registerLayoutWinProcByControlIDChain',
				[Mono.Cecil.FieldAttributes]::Public.value__ -bor [Mono.Cecil.FieldAttributes]::Static,
				$RegisterLayoutWinProcByControlIDChainType
			)
			$TinyUIFixForTS3InitialisationType.Fields.Add($TinyUIFixForTS3InitialisationRegisterLayoutWinProcByControlIDChain)

			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain = [Mono.Cecil.MethodDefinition]::new(
				'StubForRegisterLayoutWinProcByControlIDChain',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)
			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain.Parameters.Add((New-ParameterDefinition ([Mono.Cecil.ByReferenceType]::new($UI.MainModule.TypeSystem.Object)) $UI.MainModule))
			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.UInt32 $UI.MainModule))
			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.Byte $UI.MainModule))
			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.Single $UI.MainModule))
			$TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain.Parameters.Add((New-ParameterDefinition $UI.MainModule.TypeSystem.Single $UI.MainModule))
			Edit-MethodBody $TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}
			$TinyUIFixForTS3InitialisationType.Methods.Add($TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain)

			Edit-MethodBody $TinyUIFixForTS3InitialisationCCtor `
			{
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldnull)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldftn, $TinyUIFixForTS3InitialisationStubForRegisterLayoutWinProcByControlIDChain)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Newobj, (Find-InstanceMethod $RegisterLayoutWinProcByControlIDChainType .ctor System.Object, System.IntPtr))
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stsfld, $TinyUIFixForTS3InitialisationRegisterLayoutWinProcByControlIDChain)
				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}

			$TinyUIFixForTS3InitialisationRegisterLayoutWinProcs = [Mono.Cecil.MethodDefinition]::new(
				'RegisterLayoutWinProcs',
				[Mono.Cecil.MethodAttributes]::Public.value__ -bor [Mono.Cecil.MethodAttributes]::Static,
				$UI.MainModule.TypeSystem.Void
			)

			Edit-MethodBody $TinyUIFixForTS3InitialisationRegisterLayoutWinProcs `
			{
				if ($State.WinProcLayoutsByControlIDChainLength.Count -gt 0)
				{
					$NodeLocal = Add-VariableToMethod $Method $UI.MainModule.TypeSystem.Object
					$NodeAddressLocal = Add-VariableToMethod $Method ([Mono.Cecil.PointerType]::new($UI.MainModule.TypeSystem.Object))
					$InfinityLocal = Add-VariableToMethod $Method $UI.MainModule.TypeSystem.Single

					$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_R4, [Float]::PositiveInfinity)
					$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $InfinityLocal)

					$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3InitialisationRegisterLayoutWinProcByControlIDChain)

					$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloca, $NodeLocal)
					$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $NodeAddressLocal)

					$ChainLengths = $State.WinProcLayoutsByControlIDChainLength.Keys | Sort-Object -Descending

					for ($ChainLengthIndex = $ChainLengths.Count; ($ChainLengthIndex--) -gt 0;)
					{
						$ChainLength = $ChainLengths[$ChainLengthIndex]
						$WinProcLayouts = $State.WinProcLayoutsByControlIDChainLength[$ChainLength]

						for ($WinProcLayoutIndex = $WinProcLayouts.Count; ($WinProcLayoutIndex--) -gt 0;)
						{
							$WinProcLayout = $WinProcLayouts[$WinProcLayoutIndex]

							$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldnull)
							$IL.Emit([Mono.Cecil.Cil.OpCodes]::Stloc, $NodeLocal)

							for ($ControlIDIndex = $WinProcLayout.Item2.controlIDs.Count; ($ControlIDIndex--) -gt 0;)
							{
								if ($ChainLengthIndex + $WinProcLayoutIndex + $ControlIDIndex -gt 0)
								{
									$IL.Emit([Mono.Cecil.Cil.OpCodes]::Dup)
								}

								$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $NodeAddressLocal)

								$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($WinProcLayout.Item2.controlIDs[$ControlIDIndex]))

								if ($ControlIDIndex -eq 0)
								{
									$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4, [TinyUIFixForTS3Patcher.AssemblyScaling]::ReinterpretAsSigned($WinProcLayout.Item1.anchor))

									if ($WinProcLayout.Item1.type -eq [TinyUIFixForTS3Patcher.LayoutScaler+LayoutWinProc+Type]::HudLayout)
									{
										$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_R4, $WinProcLayout.Item1.dimensions.X)
										$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_R4, $WinProcLayout.Item1.dimensions.Y)
									}
									else
									{
										$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $InfinityLocal)
										$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $InfinityLocal)
									}
								}
								else
								{
									$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldc_I4_0)
									$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $InfinityLocal)
									$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ldloc, $InfinityLocal)
								}

								$IL.Emit([Mono.Cecil.Cil.OpCodes]::Callvirt, $RegisterLayoutWinProcByControlIDChainInvoke)
							}
						}
					}
				}

				$IL.Emit([Mono.Cecil.Cil.OpCodes]::Ret)
			}

			$TinyUIFixForTS3InitialisationType.Methods.Add($TinyUIFixForTS3InitialisationRegisterLayoutWinProcs)

			$UI.MainModule.Types.Add($TinyUIFixForTS3InitialisationType)


			$State.Logger.WriteInfo('Adding a hook for UIManager.RetrieveWindowInstance in UI.dll.')

			Edit-MethodBody (Find-StaticMethod $UIManagerType RetrieveWindowInstance System.UInt32, System.Type) `
			{
				$WindowBaseLocal = $Null

				do
				{
					if ($Instruction.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Call -and $Instruction.OpCode.Code -ne [Mono.Cecil.Cil.Code]::Calli)
					{
						if ($Instruction.Operand.Name -ceq 'add_Detach' -and $Instruction.Operand.DeclaringType.Name -ceq 'WindowBase' -and $Instruction.Operand.DeclaringType.Namespace -ceq 'Sims3.UI')
						{
							$AfterAddOfDetach = $Instruction.Next

							$StackDepth = 0
							$PreviousInstruction = $Instruction
							$WindowBaseLoad = $Null

							while ($PreviousInstruction = $PreviousInstruction.Previous)
							{
								$StackDepthDelta = 0

								if (-not [TinyUIFixForTS3Patcher.AssemblyScaling+OpCodeInspection]::StaticallyKnownStackDepthChangeEffectedBy($PreviousInstruction, [Ref] $StackDepthDelta))
								{
									Write-Warning "A non-statically known stack depth change was encountered while patching ""$Method"", and thus scrollbars and sliders will not be scaled.$([Environment]::NewLine)This is not a good thing."

									return
								}

								$StackDepth += $StackDepthDelta

								if ($StackDepth -eq 1)
								{
									$WindowBaseLoad = $PreviousInstruction

									break
								}
							}

							if ($Null -ne $WindowBaseLoad)
							{
								if ($Null -eq $WindowBaseLocal)
								{
									$WindowBaseLocal = Add-VariableToMethod $Method $WindowBaseType
								}

								$IL.InsertAfter($WindowBaseLoad, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Stloc, $WindowBaseLocal))
								$IL.InsertAfter($WindowBaseLoad, [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Dup))

								@(
									[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3HooksReactToRetrievedWindowInstanceAddedToCache)
									[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldloc, $WindowBaseLocal)
									[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ReactToRetrievedWindowInstanceAddedToCacheInvoke)
								).ForEach{$IL.InsertBefore($AfterAddOfDetach, $_)}
							}
						}
					}
				}
				while ($Instruction = $Instruction.Next)
			}


			$State.Logger.WriteInfo('Adding a hook for main-menu initialisation in UI.dll.')

			$MainMenuType = $UI.MainModule.GetType('Sims3.UI.GameEntry.MainMenu')

			Edit-MethodBody (Find-InstanceMethod $MainMenuType Init) `
			{
				foreach ($Return in $Returns)
				{
					@(
						($PreReturn = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld, $TinyUIFixForTS3HooksReactToInitialisationOfMainMenu))
						[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $ReactToInitialisationOfMainMenuInvoke)
					).ForEach{$IL.InsertBefore($Return, $_)}

					[TinyUIFixForTS3Patcher.AssemblyScaling+InstructionPatching]::ReplaceBranchTargetsIn($IL.Body.Instructions, $Return, $PreReturn)
				}
			}

			@{PatchedAssemblies = @(@{ResourceKey = $TinyUIFixPSForTS3ResourceKeys.UIDLL})}
		}
	}
}

