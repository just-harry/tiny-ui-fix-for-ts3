
/* SPDX-LICENSE-IDENTIFIER: BSL-1.0 */

/*
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
*/

using Mono.Cecil;
using Mono.Cecil.Cil;

using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.IO;
using System.Numerics;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml;

namespace TinyUIFixForTS3OpenSesame
{
	public class Opener
	{
		protected HashSet<string> eventNames;

		public Opener ()
		{
			this.eventNames = new HashSet<string>();
		}

		public void MakeFullyPublic (AssemblyDefinition assembly)
		{
			foreach (var module in assembly.Modules) this.MakeFullyPublic(module);
		}

		public void MakeFullyPublic (ModuleDefinition module)
		{
			foreach (var type in module.Types) this.MakeFullyPublic(type);
		}

		public void MakeFullyPublic (TypeDefinition type)
		{
			var attributes = type.Attributes;
			attributes &= ~TypeAttributes.VisibilityMask;
			attributes |= type.IsNested ? TypeAttributes.NestedPublic : TypeAttributes.Public;
			type.Attributes = attributes;

			foreach (var eventDefinition in type.Events)
			{
				this.eventNames.Add(eventDefinition.Name);
				this.MakeFullyPublic(eventDefinition);
			}

			foreach (var field in type.Fields)
			{
				if (!this.eventNames.Contains(field.Name)) this.MakeFullyPublic(field);
			}

			this.eventNames.Clear();

			foreach (var property in type.Properties) this.MakeFullyPublic(property);
			foreach (var method in type.Methods) this.MakeFullyPublic(method);
			foreach (var nestedType in type.NestedTypes) this.MakeFullyPublic(nestedType);
		}

		public void MakeFullyPublic (FieldDefinition field)
		{
			var attributes = field.Attributes;
			attributes &= ~FieldAttributes.FieldAccessMask;
			attributes |= FieldAttributes.Public;
			field.Attributes = attributes;
		}

		public void MakeFullyPublic (MethodDefinition method)
		{
			var attributes = method.Attributes;
			attributes &= ~(MethodAttributes.MemberAccessMask | MethodAttributes.CheckAccessOnOverride);
			attributes |= MethodAttributes.Public;
			method.Attributes = attributes;
		}

		public void MakeFullyPublic (PropertyDefinition property)
		{
			if (property.GetMethod != null) this.MakeFullyPublic(property.GetMethod);
			if (property.SetMethod != null) this.MakeFullyPublic(property.SetMethod);
			foreach (var otherMethod in property.OtherMethods) this.MakeFullyPublic(otherMethod);
		}

		public void MakeFullyPublic (EventDefinition eventDefinition)
		{
			if (eventDefinition.AddMethod != null) this.MakeFullyPublic(eventDefinition.AddMethod);
			if (eventDefinition.InvokeMethod != null) this.MakeFullyPublic(eventDefinition.InvokeMethod);
			if (eventDefinition.RemoveMethod != null) this.MakeFullyPublic(eventDefinition.RemoveMethod);
			foreach (var otherMethod in eventDefinition.OtherMethods) this.MakeFullyPublic(otherMethod);
		}
	}
}

