
/* SPDX-LICENSE-IDENTIFIER: BSL-1.0 */

/*
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
*/

using Sims3.SimIFace;
using Sims3.UI;

using System;
using System.Collections.Generic;
using System.Reflection;

using TinyUIFixForTS3CoreBridge;


namespace TinyUIFixForTS3
{
	public sealed class ModEntryPoint
	{
		[Tunable]
		internal static bool kInstantiator = false;

		static ModEntryPoint ()
		{
			try
			{
				foreach (var assembly in AppDomain.CurrentDomain.GetAssemblies())
				{
					try {Assimilator.Assimilate(assembly);}
					catch (Exception) {}
				}

				AppDomain.CurrentDomain.AssemblyLoad += new AssemblyLoadEventHandler(Assimilator.AssimilateLoadedAssembly);
			}
			catch (Exception)
			{}

			World.OnWorldLoadFinishedEventHandler += WorldHandling.WorldEventHandler.worldEventHandler.OnWorldLoadFinished;
		}
	}

	public static class Assimilator
	{
		internal static void AssimilateLoadedAssembly (object sender, AssemblyLoadEventArgs eventArgs)
		{
			Assimilate(eventArgs.LoadedAssembly);
		}

		public enum AssimilateTypeAs
		{
			None,
			Integration,
			Hook,
			Initialisation
		}

		public static AssimilateTypeAs TypeShouldBeAssimilatedAs (Type type)
		{
			if (type.Namespace != null)
			{
				if (type.Name == "TinyUIFixForTS3Integration") return AssimilateTypeAs.Integration;
				if (type.Name == "TinyUIFixForTS3Hooks") return AssimilateTypeAs.Hook;
				if (type.Name == "TinyUIFixForTS3Initialisation") return AssimilateTypeAs.Initialisation;
			}

			return AssimilateTypeAs.None;
		}

		public static void Assimilate (Assembly assembly)
		{
			foreach (var module in assembly.GetModules()) Assimilate(module);

			if (assembly.GetName().Name == "UI")
			{
				var tinyUIFixForTS3UIEventRegistrationEvents = assembly.ManifestModule.GetType("Sims3.UI.TinyUIFixForTS3UIEventRegistrationEvents");

				UI.EventRegistrationChangeEvents.registerEventRegistrationChangeEventHandler = Delegate.CreateDelegate(
					typeof(UI.EventRegistrationChangeEvents.UIEventRegistrationChangeEventHandlerRegistration),
					tinyUIFixForTS3UIEventRegistrationEvents.GetMethod("RegisterEventRegistrationChangeEventHandler", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static)
				) as UI.EventRegistrationChangeEvents.UIEventRegistrationChangeEventHandlerRegistration;

				UI.EventRegistrationChangeEvents.deregisterEventRegistrationChangeEventHandler = Delegate.CreateDelegate(
					typeof(UI.EventRegistrationChangeEvents.UIEventRegistrationChangeEventHandlerRegistration),
					tinyUIFixForTS3UIEventRegistrationEvents.GetMethod("DeregisterEventRegistrationChangeEventHandler", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static)
				) as UI.EventRegistrationChangeEvents.UIEventRegistrationChangeEventHandlerRegistration;
			}
		}

		public static void Assimilate (Module module)
		{
			Type[] types = null;

			try {types = module.GetTypes();}
			catch (ReflectionTypeLoadException error) {types = error.Types;}

			var integrationTypes = new List<Type>(1);
			var hookTypes = new List<Type>(1);
			var initialisationTypes = new List<Type>(1);

			foreach (var type in types)
			{
				if (type == null) continue;

				List<Type> bucket;

				switch (TypeShouldBeAssimilatedAs(type))
				{
				case AssimilateTypeAs.Integration: bucket = integrationTypes; break;
				case AssimilateTypeAs.Hook: bucket = hookTypes; break;
				case AssimilateTypeAs.Initialisation: bucket = initialisationTypes; break;
				default: continue;
				}

				bucket.Add(type);
			}

			integrationTypes.Sort((a, b) => StringComparer.Ordinal.Compare(a.FullName, b.FullName));
			foreach (var type in integrationTypes) Integrate(type);

			hookTypes.Sort((a, b) => StringComparer.Ordinal.Compare(a.FullName, b.FullName));
			foreach (var type in hookTypes) Hook(type);

			initialisationTypes.Sort((a, b) => StringComparer.Ordinal.Compare(a.FullName, b.FullName));
			foreach (var type in initialisationTypes) Initialisation(type);
		}

		public static bool Integrate (Type type)
		{
			var getUIScale = type.GetField("getUIScale", BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);

			if (getUIScale == null) return false;
			if (!getUIScale.FieldType.IsSubclassOf(typeof(Delegate))) return false;

			var invoke = getUIScale.FieldType.GetMethod("Invoke", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);

			if (!invoke.ReturnType.Equals(typeof(float))) return false;
			if (invoke.GetParameters().Length != 0) return false;

			getUIScale.SetValue(null, UIScaling.GetUIScaleGetter(getUIScale.FieldType));

			var onChangeOfGetUIScale = type.GetMethod(
				"OnChangeOfGetUIScale",
				BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static,
				null,
				new Type[]{},
				null
			);

			if (onChangeOfGetUIScale != null)
			{
				onChangeOfGetUIScale.Invoke(null, new object[]{});
			}

			return true;
		}

		public static void Hook (Type type)
		{
			SetHookField(type, "reactToRetrievedWindowInstanceAddedToCache", typeof(UI.WindowAttachmentHooks).GetMethod("ReactToRetrievedWindowInstanceAddedToCache", BindingFlags.Public | BindingFlags.Static));
			SetHookField(type, "reactToInitialisationOfMainMenu", typeof(UI.WindowAttachmentHooks).GetMethod("ReactToInitialisationOfMainMenu", BindingFlags.Public | BindingFlags.Static));
		}

		private static void SetHookField (Type type, string fieldName, MethodInfo method)
		{
			var field = type.GetField(fieldName, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static);

			if (field != null)
			{
				field.SetValue(null, Delegate.CreateDelegate(field.FieldType, method));
			}
		}

		public static void Initialisation (Type type)
		{
			var registerLayoutWinProcByControlIDChain = type.GetField(
				"registerLayoutWinProcByControlIDChain",
				BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static
			);

			if (registerLayoutWinProcByControlIDChain != null)
			{
				registerLayoutWinProcByControlIDChain.SetValue(
					null,
					Delegate.CreateDelegate(
						registerLayoutWinProcByControlIDChain.FieldType,
						typeof(UI.LayoutWinProcRegistry.LayoutWinProcsByControlIDChain).GetMethod(
							"Register",
							BindingFlags.Public | BindingFlags.Static,
							null,
							new Type[]{typeof(object).MakeByRefType(), typeof(uint), typeof(byte), typeof(float), typeof(float)},
							null
						)
					)
				);

				var registerLayoutWinProcs = type.GetMethod(
					"RegisterLayoutWinProcs",
					BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static,
					null,
					new Type[]{},
					null
				);

				if (registerLayoutWinProcs != null)
				{
					registerLayoutWinProcs.Invoke(null, null);
				}
			}
		}
	}

	public static class UIScaling
	{
		public static T GetUIScaleGetter <T> ()
		{
			return (T) GetUIScaleGetter(typeof(T));
		}

		public static object GetUIScaleGetter (Type delegateType)
		{
			return Delegate.CreateDelegate(
				delegateType,
				typeof(UIScaling).GetMethod("GetUIScale", BindingFlags.NonPublic | BindingFlags.Static)
			);
		}

		private static float GetUIScale ()
		{
			/* The actual scale gets patched into the assembly. */
			return 1f;
		}
	}

	public static class TinyUIFixForTS3Integration
	{
		public delegate float FloatGetter ();

		public static FloatGetter getUIScale = () => 1f;
	}
}


namespace TinyUIFixForTS3.WorldHandling
{
	public sealed class WorldEventHandler
	{
		public static WorldEventHandler worldEventHandler = new WorldEventHandler();

		public void OnWorldLoadFinished (object sender, EventArgs eventArgs)
		{
			UI.ControlReplacement.ControlReplacementEventHandler.SetUpUITopWindowEvents();
		}
	}
}


namespace TinyUIFixForTS3.UI
{
	public static class EventRegistrationChangeEvents
	{
		public delegate void UIEventRegistrationChangeEventHandlerRegistration (uint windowHandle, UIEventRegistrationChangeEventHandler eventHandler);

		public static UIEventRegistrationChangeEventHandlerRegistration registerEventRegistrationChangeEventHandler;
		public static UIEventRegistrationChangeEventHandlerRegistration deregisterEventRegistrationChangeEventHandler;

		public static UIManager.WindowEventData UIEventRegistryForWinHandle (uint windowHandle)
		{
			UIManager.WindowEventData registry;
			UIManager.mEventRegistry.TryGetValue(windowHandle, out registry);

			return registry;
		}
	}

	public static class DrawableHandling
	{
		public static void CopyStdDrawableToStdDrawable (StdDrawable source, StdDrawable destination)
		{
			for (int index = 0; index < 8; ++index)
			{
				var state = (DrawableBase.ControlStates) index;
				destination[state] = source[state];
			}

			destination.HitMask = source.HitMask;
			destination.ScaleType = source.ScaleType;
			destination.ScaleAmount = source.ScaleAmount;
			destination.ScaleArea = source.ScaleArea;
			destination.BevelWidth = source.BevelWidth;
			destination.GlowType = source.GlowType;
			destination.GlowMask = source.GlowMask;
			destination.GlowScale = source.GlowScale;
			destination.GlowColor = source.GlowColor;
		}

		public static void CopyImageDrawableToImageDrawable (ImageDrawable source, ImageDrawable destination)
		{
			destination.Image = source.Image;
			destination.FixedWidth = source.FixedWidth;
			destination.FixedHeight = source.FixedHeight;
			destination.Tiling = source.Tiling;
			destination.Scale = source.Scale;
			destination.HorizontalAligmnent = source.HorizontalAligmnent;
			destination.VerticalAligmnent = source.VerticalAligmnent;
			destination.DrawMask = source.DrawMask;
		}

		public static void CopyDrawableToDrawable (DrawableBase source, DrawableBase destination)
		{
			if (source is StdDrawable stdDrawableSource)
			{
				if (destination is StdDrawable stdDrawableDestination)
				{
					CopyStdDrawableToStdDrawable(stdDrawableSource, stdDrawableDestination);
				}
			}
			else if (source is ImageDrawable imageDrawableSource)
			{
				if (destination is ImageDrawable imageDrawableDestination)
				{
					CopyImageDrawableToImageDrawable(imageDrawableSource, imageDrawableDestination);
				}
			}
		}
	}

	public static class ButtonHandling
	{
		public static Vector2 AutoSize (Button button)
		{
			button.AutoSize();
			var area = button.Area;
			var topLeft = area.TopLeft;
			var bottomRight = area.BottomRight;

			float width = bottomRight.x - topLeft.x;
			float height = bottomRight.y - topLeft.y;

			return new Vector2(width, height);
		}

		public static Vector2 AutoSizeThenScaleDimensions (Button button, float scale)
		{
			button.AutoSize();
			var area = button.Area;
			var topLeft = area.TopLeft;
			var bottomRight = area.BottomRight;

			float width = (bottomRight.x - topLeft.x) * scale;
			float height = (bottomRight.y - topLeft.y) * scale;

			return new Vector2(width, height);
		}
	}

	public static class LayoutWinProcRegistry
	{
		public struct LayoutWinProc
		{
			public enum Anchor : byte
			{
				Top = 1,
				Bottom = 2,
				Left = 4,
				Right = 8
			}

			public byte anchor;
			public Vector2 dimensions;
		}

		public sealed class LayoutWinProcsByControlIDChain
		{
			public Dictionary<uint, LayoutWinProcsByControlIDChain> byControlID;
			public LayoutWinProc layoutWinProc;

			public LayoutWinProcsByControlIDChain Register (uint controlID, LayoutWinProc layoutWinProc)
			{
				if (this.byControlID as object == null)
				{
					this.byControlID = new Dictionary<uint, LayoutWinProcsByControlIDChain>(1);
				}

				LayoutWinProcsByControlIDChain child = null;

				if (!this.byControlID.TryGetValue(controlID, out child))
				{
					child = new LayoutWinProcsByControlIDChain{};
					this.byControlID[controlID] = child;
				}

				child.layoutWinProc = layoutWinProc;

				return child;
			}

			public LayoutWinProcsByControlIDChain Register (uint controlID, byte anchor, float dimensionX, float dimensionY)
			{
				return this.Register(controlID, new LayoutWinProc{anchor = anchor, dimensions = new Vector2(dimensionX, dimensionY)});
			}

			public static void Register (ref object node, uint controlID, byte anchor, float dimensionX, float dimensionY)
			{
				var parent = node == null ? registry : node as LayoutWinProcsByControlIDChain;
				node = parent.Register(controlID, anchor, dimensionX, dimensionY);
			}

			public bool LookupForWindow (WindowBase window, ref LayoutWinProc layoutWinProc)
			{
				if (window == null)
				{
					return false;
				}

				if (this.byControlID as object == null)
				{
					layoutWinProc = this.layoutWinProc;

					return true;
				}

				var controlID = window.ID;

				LayoutWinProcsByControlIDChain child = null;

				if (!this.byControlID.TryGetValue(controlID, out child))
				{
					return false;
				}

				return child.LookupForWindow(window.Parent, ref layoutWinProc);
			}
		}

		public static bool LookupForWindow (WindowBase window, ref LayoutWinProc layoutWinProc)
		{
			return registry.LookupForWindow(window, ref layoutWinProc);
		}

		public static LayoutWinProcsByControlIDChain registry = new LayoutWinProcsByControlIDChain{
			byControlID = new Dictionary<uint, LayoutWinProcsByControlIDChain>()
		};
	}

	public static class WindowAttachmentHooks
	{
		public static void ReactToInitialisationOfMainMenu ()
		{
			ControlReplacement.ControlReplacementEventHandler.SetUpUITopWindowEvents();
		}

		public static void ReactToRetrievedWindowInstanceAddedToCache (WindowBase window)
		{
			if (window is Scrollbar || window is Slider || window is TextEdit)
			{
				ControlReplacement.windowsAwaitingScaling[window.WinHandle] = window;
			}
		}
	}

	public static class ControlReplacement
	{
		public static Dictionary<uint, WindowBase> windowsAwaitingScaling = new Dictionary<uint, WindowBase>(0);
		public static ControlReplacementEventHandler eventHandler = new ControlReplacementEventHandler();

		public sealed class ControlReplacementEventHandler
		{
			public static List<uint> windowHandleRemovalList = new List<uint>(0);

			public static void SetUpUITopWindowEvents ()
			{
				var topWindow = UIManager.GetUITopWindow();

				topWindow.Tick -= ControlReplacement.eventHandler.HandleTopWindowTick;
				topWindow.Tick += ControlReplacement.eventHandler.HandleTopWindowTick;
			}

			public void HandleTopWindowTick (WindowBase sender, UIEventArgs eventArgs)
			{
				var windowsAwaitingScaling = ControlReplacement.windowsAwaitingScaling;

				if (windowsAwaitingScaling.Count > 0)
				{
					var windowHandlesToRemove = windowHandleRemovalList;

					foreach (var pair in windowsAwaitingScaling)
					{
						var window = pair.Value;

						if (
							   window.Disposed
							|| (
								  window is Scrollbar scrollbar
								? ScaledScrollbarMimic.GlomOntoScrollbar(scrollbar) != null
								: (
									  window is Slider slider
									? ScaledSliderMimic.GlomOntoSlider(slider) != null
									: ScaledScrollbarMimic.GlomOntoScrollbarsOfTextEdit(window as TextEdit) >= 0
								)
							)
						)
						{
							windowHandlesToRemove.Add(pair.Key);
						}
					}

					foreach (var key in windowHandlesToRemove)
					{
						windowsAwaitingScaling.Remove(key);
					}

					windowHandlesToRemove.Clear();
				}
			}
		}
	}


	public abstract class ScaledScrollbarMimic
	{
		public const int scaledScrollbarMimicLayoutID = 0x7085840a;
		public const int actualScrollbarGlideEffectGroupID = 0x7085850a;
		public static readonly Type scrollbarType = typeof(Scrollbar);

		public Scrollbar actualScrollbar;
		public WindowBase mimicScrollbar;
		public Button decArrow;
		public Button incArrow;
		public Button thumb;
		public Button thumbContainer;
		public WindowBase actualParent;
		public List<uint> scrollProcTargets;
		public float thumbFirstGrabbedAt = float.NaN;

		public static StopWatch autoScrollDelayTimer = StopWatch.Create(StopWatch.TickStyles.Milliseconds);
		public const float heldButtonRepetitionDelayInMS = 150;

		public abstract ResourceKey LayoutResourceKey {get;}

		private static ScaledScrollbarMimic MakeScaledScrollbarMimic (Scrollbar actualScrollbar)
		{
			if (actualScrollbar.Orientation == Scrollbar.ScrollbarOrientation.Horizontal)
			{
				return new ScaledHorizontalScrollbarMimic{actualScrollbar = actualScrollbar};
			}
			else
			{
				return new ScaledVerticalScrollbarMimic{actualScrollbar = actualScrollbar};
			}
		}

		public static ScaledScrollbarMimic GlomOntoScrollbar (Scrollbar scrollbar)
		{
			var child = scrollbar.GetChildByID(scaledScrollbarMimicLayoutID, false);

			if (child as object != null)
			{
				ScaledScrollbarMimic alreadyInitialisedMimic = MakeScaledScrollbarMimic(scrollbar);
				alreadyInitialisedMimic.mimicScrollbar = child;
				alreadyInitialisedMimic.InitialiseWindowReferences();

				return alreadyInitialisedMimic;
			}

			var mimic = MakeScaledScrollbarMimic(scrollbar);
			var mimicScrollbar = UIManager.LoadLayoutAndAddToWindow(mimic.LayoutResourceKey, scrollbar).GetWindowByExportID(scaledScrollbarMimicLayoutID);
			mimic.mimicScrollbar = mimicScrollbar;
			mimic.InitialiseWindowReferences();
			mimic.GlomOntoScrollbar();
			return mimic;
		}

		public static void ScrapeOffScrollbar (Scrollbar scrollbar)
		{
			var mimicScrollbar = scrollbar.GetChildByID(scaledScrollbarMimicLayoutID, false);

			if (mimicScrollbar as object == null)
			{
				return;
			}

			var mimic = MakeScaledScrollbarMimic(scrollbar);
			mimic.mimicScrollbar = mimicScrollbar;
			mimic.InitialiseWindowReferences();
			mimic.DetachEvents();
			mimic.ShowActualScrollbar();
			mimic.DisposeOfMimic();
		}

		public static int GlomOntoScrollbarsOfTextEdit (TextEdit textEdit)
		{
			int glomCount = 0;

			if (textEdit as object != null)
			{
				var uiManager = UIManager.gUIMgr;
				uint winHandle = textEdit.WinHandle;

				for (uint index = 0;; ++index)
				{
					var child = uiManager.GetChildByIndex(winHandle, index);

					if (child == 0) break;
					if (uiManager.GetClassID(child) == Scrollbar.ClassId)
					{
						if (GlomOntoScrollbar(UIManager.RetrieveWindowInstance(child, scrollbarType) as Scrollbar) != null)
						{
							++glomCount;
						}
						else
						{
							glomCount |= -2147483648;
						}
					}
				}
			}

			return glomCount;
		}

		public static void ScrapeOffScrollbarsOfTextEdit (TextEdit textEdit)
		{
			var uiManager = UIManager.gUIMgr;
			uint winHandle = textEdit.WinHandle;

			for (uint index = 0;; ++index)
			{
				var child = uiManager.GetChildByIndex(winHandle, index);

				if (child == 0) break;
				if (uiManager.GetClassID(child) == Scrollbar.ClassId) ScrapeOffScrollbar(UIManager.RetrieveWindowInstance(child, scrollbarType) as Scrollbar);
			}
		}

		private void GlomOntoScrollbar ()
		{
			this.MimicAppearanceOfActualScrollbar();
			var thumbContainerArea = this.MimicAreaOfActualScrollbar(this.actualScrollbar.Area);
			this.thumb.Area = this.AreaForThumb(thumbContainerArea, this.actualScrollbar.Value);
			this.HideActualScrollbar();
			this.AttachEvents();

			if (this.actualParent is TextEdit textEdit)
			{
				this.actualScrollbar.ScrollToIncrement = true;
				this.actualScrollbar.SmoothScrolling = true;
				this.AttachEventsToTextEdit(textEdit);
			}

			var actualScrollbarWinHandle = this.actualScrollbar.WinHandle;
			var actualEventData = EventRegistrationChangeEvents.UIEventRegistryForWinHandle(actualScrollbarWinHandle);

			if (actualEventData as object != null)
			{
				foreach (var eventType in actualEventData.EventTypesAndCallbacks.Keys)
				{
					this.HandleEventRegistrationChangeForActualScrollbar(actualScrollbarWinHandle, eventType, unchecked((uint) UIEventRegistrationChangeType.EventRegistered));
				}
			}
		}

		public void DisposeOfMimic ()
		{
			this.actualScrollbar.RemoveChild(this.mimicScrollbar);

			var effectList = this.mimicScrollbar.EffectList;
			var effectIndex = effectList.Count;

			while (effectIndex-- > 0)
			{
				var effect = effectList[effectIndex] as EffectBase;

				effectList.Remove(effect);
				effect.Dispose();
			}

			this.decArrow.Dispose();
			this.incArrow.Dispose();
			this.thumb.Dispose();
			this.thumbContainer.Dispose();
			this.mimicScrollbar.Dispose();
			this.actualParent = null;
		}

		private void MimicAppearanceOfActualScrollbar ()
		{
			var drawable = this.actualScrollbar.Drawable;

			if (drawable is MultiDrawable multiDrawable)
			{
				CopyScrollbarComponentDrawable(multiDrawable[(uint) Scrollbar.ScrollbarComponents.DecArrow], this.decArrow.Drawable as StdDrawable);
				CopyScrollbarComponentDrawable(multiDrawable[(uint) Scrollbar.ScrollbarComponents.Thumb], this.thumb.Drawable as StdDrawable);
				CopyScrollbarComponentDrawable(multiDrawable[(uint) Scrollbar.ScrollbarComponents.ThumbContainer], this.thumbContainer.Drawable as StdDrawable);
				CopyScrollbarComponentDrawable(multiDrawable[(uint) Scrollbar.ScrollbarComponents.IncArrow], this.incArrow.Drawable as StdDrawable);
			}
		}

		private static void CopyScrollbarComponentDrawable (DrawableBase source, StdDrawable destination)
		{
			DrawableHandling.CopyDrawableToDrawable(source, destination);
		}

		public abstract float MainAxis (Vector2 coordinate);
		public abstract ref float MainAxis (ref Vector2 coordinate);

		public abstract ref float TransverseAxis (ref Vector2 coordinate);
		public abstract float TransverseAxis (Vector2 coordinate);

		public Rect MimicAreaOfActualScrollbar (Rect actualArea)
		{
			var uiScale = TinyUIFixForTS3Integration.getUIScale();

			var decArrowDimensions = ButtonHandling.AutoSizeThenScaleDimensions(this.decArrow, uiScale);
			var incArrowDimensions = ButtonHandling.AutoSizeThenScaleDimensions(this.incArrow, uiScale);
			var thumbDimensions = ButtonHandling.AutoSizeThenScaleDimensions(this.thumb, uiScale);
			var thumbContainerDimensions = ButtonHandling.AutoSizeThenScaleDimensions(this.thumbContainer, uiScale);

			var topLeft = actualArea.TopLeft;
			var bottomRight = actualArea.BottomRight;

			var thumbWidth = this.TransverseAxis(thumbDimensions);
			float thumbContainerWidth = this.TransverseAxis(thumbContainerDimensions);
			float widthOffset = 0f;

			if (this.IsScrollProcScrollbar)
			{
				if (this.actualParent is ScrollWindow scrollWindow)
				{
					var parentArea = this.actualParent.Area;
					var parentBottomRight = parentArea.BottomRight;
					var parentTopLeft = parentArea.TopLeft;
					float parentLength = this.TransverseAxis(parentBottomRight) - this.TransverseAxis(parentTopLeft);
					float leadingGap = this.TransverseAxis(topLeft);
					float start = -leadingGap + parentLength;

					this.TransverseAxis(ref topLeft) = start - (scrollWindow.UseMiniScrollbars ? 15f : 19f) * uiScale;
					this.TransverseAxis(ref bottomRight) = start;
					this.mimicScrollbar.Area = new Rect(topLeft, bottomRight);
				}
				else
				{
					var areaWidth = this.TransverseAxis(bottomRight) - this.TransverseAxis(topLeft);
					widthOffset = areaWidth - thumbContainerWidth;
				}
			}
			else
			{
				LayoutWinProcRegistry.LayoutWinProc layoutWinProc = default;

				if (LayoutWinProcRegistry.LookupForWindow(this.actualScrollbar, ref layoutWinProc))
				{
					this.AdjustAreaForAnchor(ref topLeft, ref bottomRight, layoutWinProc.anchor, thumbContainerWidth);
				}
				else
				{
					var areaWidth = this.TransverseAxis(bottomRight) - this.TransverseAxis(topLeft);
					widthOffset = (areaWidth - thumbContainerWidth) * 0.5f;
				}

				this.mimicScrollbar.Area = new Rect(new Vector2(0f, 0f), new Vector2(bottomRight.x - topLeft.x, bottomRight.y - topLeft.y));
			}

			var areaLength = this.MainAxis(bottomRight) - this.MainAxis(topLeft);
			var transverseMiddle = widthOffset + thumbContainerWidth * 0.5f;

			var halfDecArrowWidth = this.TransverseAxis(decArrowDimensions) * 0.5f;
			this.TransverseAxis(ref topLeft) = transverseMiddle - halfDecArrowWidth;
			this.TransverseAxis(ref bottomRight) = transverseMiddle + halfDecArrowWidth;
			this.MainAxis(ref topLeft) = 0f;
			var thumbContainerLengthStart = this.MainAxis(decArrowDimensions);
			this.MainAxis(ref bottomRight) = thumbContainerLengthStart;
			this.decArrow.Area = new Rect(topLeft, bottomRight);

			var halfIncArrowWidth = this.TransverseAxis(incArrowDimensions) * 0.5f;
			this.TransverseAxis(ref topLeft) = transverseMiddle - halfIncArrowWidth;
			this.TransverseAxis(ref bottomRight) = transverseMiddle + halfIncArrowWidth;
			this.MainAxis(ref bottomRight) = areaLength;
			var thumbContainerLengthEnd = areaLength - this.MainAxis(incArrowDimensions);
			this.MainAxis(ref topLeft) = thumbContainerLengthEnd;
			this.incArrow.Area = new Rect(topLeft, bottomRight);

			this.MainAxis(ref topLeft) = thumbContainerLengthStart;
			this.MainAxis(ref bottomRight) = thumbContainerLengthEnd;

			this.TransverseAxis(ref topLeft) = widthOffset;
			this.TransverseAxis(ref bottomRight) = widthOffset + thumbContainerWidth;

			var thumbContainerArea = new Rect(topLeft, bottomRight);
			this.thumbContainer.Area = thumbContainerArea;

			var halfThumbWidth = thumbWidth * 0.5f;

			this.TransverseAxis(ref topLeft) = transverseMiddle - halfThumbWidth;
			this.TransverseAxis(ref bottomRight) = transverseMiddle + halfThumbWidth;

			this.MainAxis(ref bottomRight) = this.MainAxis(thumbDimensions);

			this.thumb.Area = new Rect(topLeft, bottomRight);

			return thumbContainerArea;
		}

		public abstract void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float scrollbarWidth);
		public abstract bool IsScrollProcScrollbar {get;}
		public abstract LayoutWinProcRegistry.LayoutWinProc.Anchor ScrollProcAnchor {get;}

		public Rect AreaForThumb (Rect thumbContainerArea, int value)
		{
			var topLeft = thumbContainerArea.TopLeft;
			var bottomRight = thumbContainerArea.BottomRight;
			float length = this.MainAxis(bottomRight) - this.MainAxis(topLeft);

			float thumbLength = this.ThumbLengthForScrollbar(length, this.actualScrollbar.MinThumbSize, this.actualScrollbar.UpperBoundValue, this.actualScrollbar.VisibleRange);

			float valueRange = this.actualScrollbar.UpperBoundValue - this.actualScrollbar.VisibleRange;
			float movementRange = length - thumbLength;

			float startOffset = ((float) value / valueRange) * movementRange;

			float start = this.MainAxis(topLeft) + startOffset;

			var thumbArea = this.thumb.Area;
			var thumbTopLeft = thumbArea.TopLeft;
			var thumbBottomRight = thumbArea.BottomRight;

			this.TransverseAxis(ref topLeft) = this.TransverseAxis(thumbTopLeft);
			this.MainAxis(ref topLeft) = start;
			this.TransverseAxis(ref bottomRight) = this.TransverseAxis(thumbBottomRight);
			this.MainAxis(ref bottomRight) = start + thumbLength;

			return new Rect(topLeft, bottomRight);
		}

		public static float ValueForThumb (float thumbContainerLength, float thumbOffset, float thumbLength, int valueRange)
		{
			float movementRange = thumbContainerLength - thumbLength;
			return (thumbOffset / movementRange) * (float) valueRange;
		}

		public float ThumbLengthForScrollbar (float thumbContainerLength, float minimumThumbLength, int upperBound, int visibleRange)
		{
			float size = visibleRange <= upperBound ? visibleRange : upperBound;
			float length = (size / (float) upperBound) * thumbContainerLength;
			return length >= minimumThumbLength ? length : minimumThumbLength;
		}

		public delegate void AdjustScrollBarByDelta (int delta);

		public void DecrementActualScrollbarBy (int delta)
		{
			var value = this.actualScrollbar.Value;
			var adjustedValue = value - delta;
			var minimumValue = this.actualScrollbar.MinValue;

			adjustedValue = adjustedValue >= minimumValue ? adjustedValue : minimumValue;

			var isScrollProcScrollbar = this.IsScrollProcScrollbar;

			if (isScrollProcScrollbar)
			{
				this.InitialiseScrollProcState();
				this.PositionTargetsOfScrollProc(value, adjustedValue);
				this.DeinitialiseScrollProcState();
			}

			if (!(this.actualParent is TextEdit)) this.actualScrollbar.Value = adjustedValue;

			this.actualScrollbar.TargetValue = adjustedValue;

			if (!isScrollProcScrollbar) this.MimicScrollbarValueChangeEvent(value, adjustedValue);
		}

		public void IncrementActualScrollbarBy (int delta)
		{
			var value = this.actualScrollbar.Value;
			var adjustedValue = value + delta;
			var visible = this.actualScrollbar.VisibleRange;
			var upperBound = this.actualScrollbar.UpperBoundValue;
			visible = visible <= upperBound ? visible : upperBound;
			var maximumValue = upperBound - visible;

			adjustedValue = adjustedValue <= maximumValue ? adjustedValue : maximumValue;

			var isScrollProcScrollbar = this.IsScrollProcScrollbar;

			if (isScrollProcScrollbar)
			{
				this.InitialiseScrollProcState();
				this.PositionTargetsOfScrollProc(value, adjustedValue);
				this.DeinitialiseScrollProcState();
			}

			if (!(this.actualParent is TextEdit)) this.actualScrollbar.Value = adjustedValue;

			this.actualScrollbar.TargetValue = adjustedValue;

			if (!isScrollProcScrollbar) this.MimicScrollbarValueChangeEvent(value, adjustedValue);
		}

		public void HideActualScrollbar ()
		{
			var hideActual = new GlideEffect();
			hideActual.Offset = new Vector2(2097152f, 0f);
			hideActual.Duration = 0f;
			hideActual.TriggerType = EffectBase.TriggerTypes.Manual;
			hideActual.GroupID = actualScrollbarGlideEffectGroupID;
			this.actualScrollbar.EffectList.Add(hideActual);
			hideActual.TriggerEffect(false);

			var showMimic = new GlideEffect();
			showMimic.Offset = new Vector2(-2097152f, 0f);
			showMimic.Duration = 0f;
			showMimic.TriggerType = EffectBase.TriggerTypes.Manual;
			this.mimicScrollbar.EffectList.Add(showMimic);
			showMimic.TriggerEffect(false);
		}

		public void ShowActualScrollbar ()
		{
			var effectList = this.actualScrollbar.EffectList;
			var effectIndex = effectList.Count;

			while (effectIndex-- > 0)
			{
				var effect = effectList[effectIndex] as EffectBase;

				if (effect.GroupID == actualScrollbarGlideEffectGroupID)
				{
					effectList.Remove(effect);
					effect.Dispose();
				}
			}
		}

		public void InitialiseWindowReferences ()
		{
			this.decArrow = this.mimicScrollbar.GetChildByID(2, false) as Button;
			this.incArrow = this.mimicScrollbar.GetChildByID(3, false) as Button;
			this.thumb = this.mimicScrollbar.GetChildByID(4, false) as Button;
			this.thumbContainer = this.mimicScrollbar.GetChildByID(5, false) as Button;
			this.actualParent = this.actualScrollbar.Parent;
		}

		public void AttachEvents ()
		{
			this.AttachEventsToDecArrow();
			this.AttachEventsToIncArrow();
			this.AttachEventsToThumb();
			this.AttachEventsToThumbContainer();
			this.AttachEventsToActualScrollbar();
		}

		public void DetachEvents ()
		{
			this.DetachEventsFromDecArrow();
			this.DetachEventsFromIncArrow();
			this.DetachEventsFromThumb();
			this.DetachEventsFromThumbContainer();
			this.DetachEventsFromActualScrollbar();
		}

		public void AttachEventsToDecArrow ()
		{
			this.decArrow.MouseDown += this.HandleDecArrowMouseDown;
			this.decArrow.MouseUp += this.HandleDecArrowMouseUp;
		}

		public void DetachEventsFromDecArrow ()
		{
			this.decArrow.MouseDown -= this.HandleDecArrowMouseDown;
			this.decArrow.MouseUp -= this.HandleDecArrowMouseUp;
		}

		public void AttachEventsToIncArrow ()
		{
			this.incArrow.MouseDown += this.HandleIncArrowMouseDown;
			this.incArrow.MouseUp += this.HandleIncArrowMouseUp;
		}

		public void DetachEventsFromIncArrow ()
		{
			this.incArrow.MouseDown -= this.HandleIncArrowMouseDown;
			this.incArrow.MouseUp -= this.HandleIncArrowMouseUp;
		}

		public void AttachEventsToThumb ()
		{
			this.thumb.MouseDown += this.HandleThumbMouseDown;
			this.thumb.MouseUp += this.HandleThumbMouseUp;
		}

		public void DetachEventsFromThumb ()
		{
			this.thumb.MouseDown -= this.HandleThumbMouseDown;
			this.thumb.MouseUp -= this.HandleThumbMouseUp;
		}

		public void AttachEventsToThumbContainer ()
		{
			this.thumbContainer.MouseDown += this.HandleThumbContainerMouseDown;
		}

		public void DetachEventsFromThumbContainer ()
		{
			this.thumbContainer.MouseDown -= this.HandleThumbContainerMouseDown;
		}

		public void AttachEventsToActualScrollbar ()
		{
			this.actualScrollbar.Detach += this.HandleDetachOfActualScrollbar;
			this.actualScrollbar.Attach += this.HandleAttachOfActualScrollbar;
			this.actualScrollbar.AreaChange += this.MimicAreaOfActualScrollbarOnChangeOfArea;
			this.actualScrollbar.VisibilityChange += this.MimicVisibilityOfActualScrollbarOnChangeOfVisibility;
			this.actualScrollbar.ScrollbarValueChange += this.HandleScrollbarValueChange;
			EventRegistrationChangeEvents.registerEventRegistrationChangeEventHandler(this.actualScrollbar.WinHandle, this.HandleEventRegistrationChangeForActualScrollbar);

		}

		public void DetachEventsFromActualScrollbar ()
		{
			this.actualScrollbar.Detach -= this.HandleDetachOfActualScrollbar;
			this.actualScrollbar.Attach -= this.HandleAttachOfActualScrollbar;
			this.actualScrollbar.AreaChange -= this.MimicAreaOfActualScrollbarOnChangeOfArea;
			this.actualScrollbar.VisibilityChange -= this.MimicVisibilityOfActualScrollbarOnChangeOfVisibility;
			this.actualScrollbar.ScrollbarValueChange -= this.HandleScrollbarValueChange;
			EventRegistrationChangeEvents.deregisterEventRegistrationChangeEventHandler(this.actualScrollbar.WinHandle, this.HandleEventRegistrationChangeForActualScrollbar);
		}

		public void AttachEventsToTextEdit (TextEdit textEdit)
		{
			textEdit.Tick += this.HandleTextEditTick;
		}

		public void DetachEventsFromTextEdit (TextEdit textEdit)
		{
			textEdit.Tick -= this.HandleTextEditTick;
		}

		public void HandleAttachOfActualScrollbar (WindowBase sender, UIEventArgs eventArgs)
		{
			this.actualParent = this.actualScrollbar.Parent;
		}

		public void HandleDetachOfActualScrollbar (WindowBase sender, UIEventArgs eventArgs)
		{
			if (this.actualParent is TextEdit textEdit)
			{
				this.DetachEventsFromTextEdit(textEdit);
			}

			this.actualParent = null;
		}

		public void HandleTextEditTick (WindowBase sender, UIEventArgs eventArgs)
		{
			this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, this.actualScrollbar.TargetValue);
		}

		public void StartChangingScrollbarValue ()
		{
			this.actualScrollbar.ScrollbarValueChange -= this.HandleScrollbarValueChange;
			this.actualScrollbar.AreaChange -= this.MimicAreaOfActualScrollbarOnChangeOfArea;
		}

		public void StopChangingScrollbarValue ()
		{
			this.actualScrollbar.ScrollbarValueChange += this.HandleScrollbarValueChange;
			this.actualScrollbar.AreaChange += this.MimicAreaOfActualScrollbarOnChangeOfArea;
		}

		public void HandleEventRegistrationChangeForActualScrollbar (uint windowHandle, uint eventType, uint eventChangeType)
		{
			if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.AllEventsDeregistered))
			{
				for (uint index = 4; index-- > 0;)
				{
					WindowBase control = null;
					switch (index)
					{
					case 0: control = this.thumb; break;
					case 1: control = this.thumbContainer; break;
					case 2: control = this.decArrow; break;
					case 3: control = this.incArrow; break;
					}

					control.MouseDown -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.MouseUp -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.MouseMove -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.MouseWheel -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.HitTest -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.TriggerDown -= this.ForwardUIEventToActualScrollbar;
					control.TriggerUp -= this.ForwardUIEventToActualScrollbar;
					control.FocusAcquired -= this.ForwardUIEventToActualScrollbar;
					control.FocusLost -= this.ForwardUIEventToActualScrollbar;
					control.DragEnter -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.DragLeave -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.DragOver -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.DragDrop -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.DragEnd -= this.ForwardUIEventWithMousePositionToActualScrollbar;
					control.DragQueryContinue -= this.ForwardUIEventToActualScrollbar;
				}

				return;
			}


			for (uint index = 4; index-- > 0;)
			{
				WindowBase control = null;
				switch (index)
				{
				case 0: control = this.thumb; break;
				case 1: control = this.thumbContainer; break;
				case 2: control = this.decArrow; break;
				case 3: control = this.incArrow; break;
				}

				switch (eventType)
				{
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseDown): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseDown += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.MouseDown -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseUp): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseUp += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.MouseUp -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseMove): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseMove += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.MouseMove -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseWheel): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseWheel += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.MouseWheel -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseHitTest): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.HitTest += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.HitTest -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseTriggerDown): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.TriggerDown += this.ForwardUIEventToActualScrollbar; else control.TriggerDown -= this.ForwardUIEventToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseTriggerUp): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.TriggerUp += this.ForwardUIEventToActualScrollbar; else control.TriggerUp -= this.ForwardUIEventToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseFocusAcquired): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.FocusAcquired += this.ForwardUIEventToActualScrollbar; else control.FocusAcquired -= this.ForwardUIEventToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseFocusLost): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.FocusLost += this.ForwardUIEventToActualScrollbar; else control.FocusLost -= this.ForwardUIEventToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragEnter): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragEnter += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.DragEnter -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragLeave): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragLeave += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.DragLeave -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragOver): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragOver += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.DragOver -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragDrop): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragDrop += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.DragDrop -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragEnd): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragEnd += this.ForwardUIEventWithMousePositionToActualScrollbar; else control.DragEnd -= this.ForwardUIEventWithMousePositionToActualScrollbar; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragQueryContinue): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragQueryContinue += this.ForwardUIEventToActualScrollbar; else control.DragQueryContinue -= this.ForwardUIEventToActualScrollbar; break;
				}
			}
		}

		public void HandleScrollbarValueChange (WindowBase sender, UIValueChangedEventArgs eventArgs)
		{
			if (!(this.actualParent is TextEdit) || this.actualScrollbar.TargetValue == eventArgs.NewValue)
			{
				this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, eventArgs.NewValue);
			}
		}

		public void HandleDecArrowMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseDown(this.decArrow, eventArgs, this.DecrementActualScrollbarBy, this.HandleDecArrowMouseMove, this.HandleDecArrowFocusLost);
		}

		public void HandleDecArrowMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseMove(this.decArrow, eventArgs, this.incArrow, this.DecrementActualScrollbarBy);
		}

		public void HandleDecArrowMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseUp(this.decArrow, eventArgs, this.HandleDecArrowMouseMove, this.HandleDecArrowFocusLost);
		}

		public void HandleDecArrowFocusLost (WindowBase sender, UIFocusChangeEventArgs eventArgs)
		{
			this.HandleArrowFocusLost(this.decArrow, eventArgs, this.HandleDecArrowFocusLost);
		}

		public void HandleIncArrowMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseDown(this.incArrow, eventArgs, this.IncrementActualScrollbarBy, this.HandleIncArrowMouseMove, this.HandleIncArrowFocusLost);
		}

		public void HandleIncArrowMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseMove(this.incArrow, eventArgs, this.decArrow, this.IncrementActualScrollbarBy);
		}

		public void HandleIncArrowMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleArrowMouseUp(this.incArrow, eventArgs, this.HandleIncArrowMouseMove, this.HandleIncArrowFocusLost);
		}

		public void HandleIncArrowFocusLost (WindowBase sender, UIFocusChangeEventArgs eventArgs)
		{
			this.HandleArrowFocusLost(this.incArrow, eventArgs, this.HandleIncArrowFocusLost);
		}

		public void HandleArrowMouseDown (
			Button arrow,
			UIMouseEventArgs eventArgs,
			AdjustScrollBarByDelta adjustScrollbar,
			UIEventHandler<UIMouseEventArgs> onMouseMove,
			UIEventHandler<UIFocusChangeEventArgs> onFocusLost
		)
		{
			arrow.FocusLost -= onFocusLost;

			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.SetCaptureTarget(InputContext.kICMouse, arrow);

				this.StartChangingScrollbarValue();

				adjustScrollbar(this.actualScrollbar.ArrowDelta);

				autoScrollDelayTimer.Restart();

				this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, this.actualScrollbar.Value);

				var drawable = arrow.Drawable as StdDrawable;
				drawable[DrawableBase.ControlStates.kCheckedActive] = drawable[DrawableBase.ControlStates.kActive];
				arrow.MouseMove += onMouseMove;

				eventArgs.Handled = true;
			}
		}

		public void HandleArrowMouseMove (
			Button arrow,
			UIMouseEventArgs eventArgs,
			Button oppositeArrow,
			AdjustScrollBarByDelta adjustScrollbar
		)
		{
			var window = UIManager.GetWindowFromPoint(arrow.WindowToScreen(eventArgs.MousePosition));
			var windowHandle = window.WinHandle;

			var drawable = arrow.Drawable as StdDrawable;

			if (windowHandle == arrow.WinHandle)
			{
				drawable.GlowType = StdDrawable.GlowingType.kGlowOnHiliteOnly;
				drawable[DrawableBase.ControlStates.kActive] = drawable[DrawableBase.ControlStates.kCheckedActive];

				arrow.Highlighted = true;
				arrow.Invalidate();

				if (
					   autoScrollDelayTimer.GetElapsedTimeFloat() >= heldButtonRepetitionDelayInMS
					|| !autoScrollDelayTimer.IsRunning()
				)
				{
					adjustScrollbar(this.actualScrollbar.ArrowDelta);

					autoScrollDelayTimer.Restart();

					this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, this.actualScrollbar.Value);
				}
			}
			else
			{
				autoScrollDelayTimer.Stop();

				drawable.GlowType = StdDrawable.GlowingType.kGlowNever;
				drawable[DrawableBase.ControlStates.kActive] = drawable[DrawableBase.ControlStates.kNormal];

				arrow.Highlighted = false;
				arrow.Invalidate();

				if (windowHandle == this.thumb.WinHandle || windowHandle == oppositeArrow.WinHandle)
				{
					var button = window as Button;
					button.Highlighted = true;
				}
				else
				{
					this.thumb.Highlighted = false;
					oppositeArrow.Highlighted = false;
				}
			}

			eventArgs.Handled = true;
		}

		public void HandleArrowMouseUp (
			Button arrow,
			UIMouseEventArgs eventArgs,
			UIEventHandler<UIMouseEventArgs> onMouseMove,
			UIEventHandler<UIFocusChangeEventArgs> onFocusLost
		)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				this.StopChangingScrollbarValue();

				UIManager.ReleaseCapture(InputContext.kICMouse, arrow);
				arrow.MouseMove -= onMouseMove;

				var drawable = arrow.Drawable as StdDrawable;

				drawable[DrawableBase.ControlStates.kActive] = drawable[DrawableBase.ControlStates.kCheckedActive];
				drawable.GlowType = StdDrawable.GlowingType.kGlowOnHiliteOnly;

				if (UIManager.GetWindowFromPoint(arrow.WindowToScreen(eventArgs.MousePosition)).WinHandle == arrow.WinHandle)
				{
					arrow.Highlighted = true;
					arrow.Invalidate();
					arrow.FocusLost += onFocusLost;
				}
				else
				{
					arrow.Highlighted = false;
					arrow.Invalidate();
				}

				eventArgs.Handled = true;
			}
		}

		public void HandleArrowFocusLost (
			Button arrow,
			UIFocusChangeEventArgs eventArgs,
			UIEventHandler<UIFocusChangeEventArgs> onFocusLost
		)
		{
			arrow.FocusLost -= onFocusLost;
			arrow.Highlighted = false;
			arrow.Invalidate();
		}

		public void HandleThumbContainerMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.SetCaptureTarget(InputContext.kICMouse, this.thumbContainer);

				this.StartChangingScrollbarValue();

				if (this.MainAxis(this.thumbContainer.WindowToScreen(eventArgs.MousePosition)) <= this.MainAxis(this.actualScrollbar.WindowToScreen(this.thumb.Area.TopLeft)))
				{
					this.DecrementActualScrollbarBy(this.actualScrollbar.VisibleRange);
					this.thumbContainer.MouseUp += this.HandleThumbContainerDecMouseUp;
					this.thumbContainer.MouseMove += this.HandleThumbContainerDecMouseMove;
				}
				else
				{
					this.IncrementActualScrollbarBy(this.actualScrollbar.VisibleRange);
					this.thumbContainer.MouseUp += this.HandleThumbContainerIncMouseUp;
					this.thumbContainer.MouseMove += this.HandleThumbContainerIncMouseMove;
				}

				autoScrollDelayTimer.Restart();

				eventArgs.Handled = true;
			}
		}

		public void HandleThumbContainerDecMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if (this.MainAxis(this.thumbContainer.WindowToScreen(eventArgs.MousePosition)) <= this.MainAxis(this.actualScrollbar.WindowToScreen(this.thumb.Area.TopLeft)))
			{
				this.HandleThumbContainerMouseMove(eventArgs, this.DecrementActualScrollbarBy);
			}
		}

		public void HandleThumbContainerIncMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if (this.MainAxis(this.thumbContainer.WindowToScreen(eventArgs.MousePosition)) > this.MainAxis(this.actualScrollbar.WindowToScreen(this.thumb.Area.TopLeft)))
			{
				this.HandleThumbContainerMouseMove(eventArgs, this.IncrementActualScrollbarBy);
			}
		}

		public void HandleThumbContainerMouseMove (UIMouseEventArgs eventArgs, AdjustScrollBarByDelta adjustScrollbar)
		{
			var window = UIManager.GetWindowFromPoint(this.thumbContainer.WindowToScreen(eventArgs.MousePosition));
			var windowHandle = window.WinHandle;

			if (windowHandle == this.thumbContainer.WinHandle)
			{
				if (
					   autoScrollDelayTimer.GetElapsedTimeFloat() >= heldButtonRepetitionDelayInMS
					|| !autoScrollDelayTimer.IsRunning()
				)
				{
					adjustScrollbar(this.actualScrollbar.VisibleRange);

					autoScrollDelayTimer.Restart();

					this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, this.actualScrollbar.Value);
				}
			}
			else
			{
				autoScrollDelayTimer.Stop();

				if (windowHandle == this.thumb.WinHandle || windowHandle == this.decArrow.WinHandle || windowHandle == this.incArrow.WinHandle)
				{
					var button = window as Button;
					button.Highlighted = true;
					button.Invalidate();
				}
				else
				{
					this.thumb.Highlighted = false;
					this.thumb.Invalidate();
					this.decArrow.Highlighted = false;
					this.decArrow.Invalidate();
					this.incArrow.Highlighted = false;
					this.incArrow.Invalidate();
				}
			}

			eventArgs.Handled = true;
		}

		public void HandleThumbContainerDecMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleThumbContainerMouseUp(eventArgs, this.HandleThumbContainerDecMouseUp, this.HandleThumbContainerDecMouseMove);
		}

		public void HandleThumbContainerIncMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			this.HandleThumbContainerMouseUp(eventArgs, this.HandleThumbContainerIncMouseUp, this.HandleThumbContainerIncMouseMove);
		}

		public void HandleThumbContainerMouseUp (
			UIMouseEventArgs eventArgs,
			UIEventHandler<UIMouseEventArgs> onMouseUp,
			UIEventHandler<UIMouseEventArgs> onMouseMove
		)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				this.StopChangingScrollbarValue();

				UIManager.ReleaseCapture(InputContext.kICMouse, this.thumbContainer);
				this.thumbContainer.MouseUp -= onMouseUp;
				this.thumbContainer.MouseMove -= onMouseMove;

				eventArgs.Handled = true;
			}
		}

		public void MimicAreaOfActualScrollbarOnChangeOfArea (WindowBase sender, UIAreaChangeEventArgs eventArgs)
		{
			this.MimicAppearanceOfActualScrollbar();
			var thumbContainerArea = this.MimicAreaOfActualScrollbar(eventArgs.NewArea);
			this.thumb.Area = this.AreaForThumb(thumbContainerArea, this.actualScrollbar.Value);
		}

		public void MimicVisibilityOfActualScrollbarOnChangeOfVisibility (WindowBase sender, UIVisibilityChangeEventArgs eventArgs)
		{
			this.mimicScrollbar.Visible = eventArgs.Visible;
		}

		public static void FindScrollProcTargets (uint scrollbarHandle, WindowBase scrollbarParent, List<uint> sink)
		{
			var uiManager = UIManager.gUIMgr;
			uint winHandle = scrollbarParent.WinHandle;

			for (uint index = 0;; ++index)
			{
				var child = uiManager.GetChildByIndex(winHandle, index);

				if (child == 0) break;
				if (child == scrollbarHandle) continue;

				sink.Add(child);
			}
		}

		public void InitialiseScrollProcState ()
		{
			this.scrollProcTargets = new List<uint>();
			FindScrollProcTargets(this.actualScrollbar.WinHandle, this.actualParent, this.scrollProcTargets);
		}

		public void DeinitialiseScrollProcState ()
		{
			this.scrollProcTargets.Clear();
			this.scrollProcTargets.Capacity = 0;
			this.scrollProcTargets = null;
		}

		/* `at` must be relative to the top-left of the thumb. */
		public void GrabThumb (Vector2 at)
		{
			this.StartChangingScrollbarValue();

			this.thumbFirstGrabbedAt = this.MainAxis(at);

			if (this.IsScrollProcScrollbar) this.InitialiseScrollProcState();
		}

		public void ReleaseThumb ()
		{
			this.StopChangingScrollbarValue();

			this.thumbFirstGrabbedAt = float.NaN;

			if (this.IsScrollProcScrollbar) this.DeinitialiseScrollProcState();
		}

		/* `to` must be relative to the top-left of the thumb. */
		public void MoveThumb (Vector2 to)
		{
			var thumbArea = this.thumb.Area;
			var topLeft = thumbArea.TopLeft;
			var bottomRight = thumbArea.BottomRight;
			var thumbStart = this.MainAxis(topLeft);
			var thumbEnd = this.MainAxis(bottomRight);
			var thumbLength = thumbEnd - thumbStart;

			float adjustedStart = this.MainAxis(this.mimicScrollbar.ScreenToWindow(this.thumb.WindowToScreen(to))) - this.thumbFirstGrabbedAt;
			float delta = adjustedStart - thumbStart;
			float adjustedEnd = thumbEnd + delta;

			var thumbContainerArea = this.thumbContainer.Area;
			float topBound = this.MainAxis(thumbContainerArea.TopLeft);
			float bottomBound = this.MainAxis(thumbContainerArea.BottomRight);
			float thumbContainerLength = bottomBound - topBound;

			float topExcess = topBound - adjustedStart;
			topExcess = topExcess <= 0 ? 0 : topExcess;
			float bottomExcess = adjustedEnd - bottomBound;
			bottomExcess = bottomExcess <= 0 ? 0 : bottomExcess;
			float excess = topExcess - bottomExcess;

			var top = adjustedStart + excess;

			int value = (int) Math.Round(
				ValueForThumb(
					thumbContainerLength,
					top - topBound,
					thumbLength,
					this.actualScrollbar.UpperBoundValue - this.actualScrollbar.VisibleRange
				)
			);
			int activeValue = this.actualScrollbar.Value;

			if (value != activeValue)
			{
				this.thumb.Area = this.AreaForThumb(thumbContainerArea, value);

				var isScrollProcScrollbar = this.IsScrollProcScrollbar;

				if (isScrollProcScrollbar) this.PositionTargetsOfScrollProc(activeValue, value);
				if (!(this.actualParent is TextEdit)) this.actualScrollbar.Value = value;
				this.actualScrollbar.TargetValue = value;

				if (!isScrollProcScrollbar) this.MimicScrollbarValueChangeEvent(activeValue, value);
			}
			else if (this.actualScrollbar.SmoothScrolling)
			{
				this.MainAxis(ref topLeft) = top;
				this.MainAxis(ref bottomRight) = adjustedEnd + excess;
				this.thumb.Area = new Rect(topLeft, bottomRight);
			}
		}

		public void PositionTargetsOfScrollProc (int oldValue, int newValue)
		{
			float range = this.actualScrollbar.UpperBoundValue;
			float length = 0f;
			uint index = 0;

			unsafe
			{
				Vector2* targetAreas = stackalloc Vector2[this.scrollProcTargets.Count << 1];

				foreach (var target in this.scrollProcTargets)
				{
					var area = UIManager.GetRectProperty(target, (uint) WindowBase.PropertyID.kPropWindowArea);
					targetAreas[index] = area.BottomRight;
					var end = this.MainAxis(targetAreas[index]);
					++index;
					targetAreas[index] = area.TopLeft;
					var start = this.MainAxis(targetAreas[index]);

					var mainLength = end - start;
					length = mainLength >= length ? mainLength : length;

					++index;
				}

				float differenceFraction = (float) (oldValue - newValue) / range;
				float positionAdjustment = length * differenceFraction;
				index = 0;

				foreach (var target in this.scrollProcTargets)
				{
					this.MainAxis(ref targetAreas[index]) += positionAdjustment;
					++index;
					this.MainAxis(ref targetAreas[index]) += positionAdjustment;
					UIManager.SetRectProperty(target, (uint) WindowBase.PropertyID.kPropWindowArea, new Rect(targetAreas[index], targetAreas[index - 1]));
					++index;
				}
			}
		}

		public void HandleThumbMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.SetCaptureTarget(InputContext.kICMouse, this.thumb);
				this.thumb.MouseMove += this.HandleThumbMouseMove;
				this.GrabThumb(eventArgs.MousePosition);
				eventArgs.Handled = true;
			}
		}

		public void HandleThumbMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				this.thumb.MouseMove -= this.HandleThumbMouseMove;
				UIManager.ReleaseCapture(InputContext.kICMouse, this.thumb);
				this.ReleaseThumb();
				eventArgs.Handled = true;
			}
		}

		public void HandleThumbMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			#pragma warning disable CS1718
			if (this.thumbFirstGrabbedAt == this.thumbFirstGrabbedAt)
			#pragma warning disable CS1718
			{
				this.MoveThumb(eventArgs.MousePosition);
				eventArgs.Handled = true;
			}
		}

		public void MimicScrollbarValueChangeEvent (int oldValue, int newValue)
		{
			bool result = false;

			UIManager.ProcessEvent(
				this.actualScrollbar.WinHandle,
				unchecked((uint) Scrollbar.ScrollbarEvents.kEventScrollbarValueChanged),
				this.actualScrollbar,
				this.actualParent,
				unchecked((int) this.actualScrollbar.ID),
				ref oldValue,
				newValue,
				0,
				0,
				0,
				0,
				ref result,
				null
			);
		}

		public void ForwardUIEventToActualScrollbar (WindowBase sender, UIEventArgs eventArgs)
		{
			UIManager.ProcessEvent(
				this.actualScrollbar.WinHandle,
				eventArgs.mType,
				this.actualScrollbar,
				this.actualScrollbar,
				eventArgs.mArg1,
				ref eventArgs.mArg2,
				eventArgs.mArg3,
				eventArgs.mF1,
				eventArgs.mF2,
				eventArgs.mF3,
				eventArgs.mF4,
				ref eventArgs.mResult,
				eventArgs.mText
			);
		}

		public void ForwardUIEventWithMousePositionToActualScrollbar (WindowBase sender, UIEventArgs eventArgs)
		{
			var mousePosition = new Vector2(eventArgs.mF1, eventArgs.mF2);
			mousePosition = this.mimicScrollbar.ScreenToWindow(sender.WindowToScreen(mousePosition));
			this.TransverseAxis(ref mousePosition) /= TinyUIFixForTS3Integration.getUIScale();

			UIManager.ProcessEvent(
				this.actualScrollbar.WinHandle,
				eventArgs.mType,
				this.actualScrollbar,
				this.actualScrollbar,
				eventArgs.mArg1,
				ref eventArgs.mArg2,
				eventArgs.mArg3,
				mousePosition.x,
				mousePosition.y,
				eventArgs.mF3,
				eventArgs.mF4,
				ref eventArgs.mResult,
				eventArgs.mText
			);
		}
	}

	public class ScaledVerticalScrollbarMimic : ScaledScrollbarMimic
	{
		public override ResourceKey LayoutResourceKey => new ResourceKey(0x81aef1dbd79895f8, 0x025c95b6, 0x84857051);

		public override ref float MainAxis (ref Vector2 coordinate)
		{
			return ref coordinate.y;
		}

		public override float MainAxis (Vector2 coordinate)
		{
			return coordinate.y;
		}

		public override ref float TransverseAxis (ref Vector2 coordinate)
		{
			return ref coordinate.x;
		}

		public override float TransverseAxis (Vector2 coordinate)
		{
			return coordinate.x;
		}

		public override void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float scrollbarWidth)
		{
			var parentArea = this.actualParent.Area;
			var parentTopLeft = parentArea.TopLeft;
			var parentBottomRight = parentArea.BottomRight;
			var verticalAnchor = anchor & (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Top | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom);

			topLeft.x = -topLeft.x;
			bottomRight.x = topLeft.x + scrollbarWidth;

			if (verticalAnchor == (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Top | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom))
			{
				float parentLength = parentBottomRight.y - parentTopLeft.y;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap;
				bottomRight.y = topLeft.y + parentLength;
			}
			else if (verticalAnchor == (uint) LayoutWinProcRegistry.LayoutWinProc.Anchor.Top)
			{
				float scrollbarLength = bottomRight.y - topLeft.y;
				scrollbarLength = scrollbarLength >= 0f ? scrollbarLength : -scrollbarLength;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap;
				bottomRight.y = topLeft.y + scrollbarLength;
			}
			else if (verticalAnchor != 0)
			{
				float parentLength = parentBottomRight.y - parentTopLeft.y;
				float scrollbarLength = bottomRight.y - topLeft.y;
				scrollbarLength = scrollbarLength >= 0f ? scrollbarLength : -scrollbarLength;
				float scrollbarOffset = parentLength - scrollbarLength;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap + scrollbarOffset;
				bottomRight.y = topLeft.y + scrollbarLength;
			}
		}

		public override bool IsScrollProcScrollbar => this.actualScrollbar.ID == (uint) Window.ScrollProcOrientation.kScrollbarID_Vertical;

		public override LayoutWinProcRegistry.LayoutWinProc.Anchor ScrollProcAnchor => (
			LayoutWinProcRegistry.LayoutWinProc.Anchor.Top | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right
		);
	}

	public class ScaledHorizontalScrollbarMimic : ScaledScrollbarMimic
	{
		public override ResourceKey LayoutResourceKey => new ResourceKey(0xcd5e4225f2eec646, 0x025c95b6, 0x84857051);

		public override ref float MainAxis (ref Vector2 coordinate)
		{
			return ref coordinate.x;
		}

		public override float MainAxis (Vector2 coordinate)
		{
			return coordinate.x;
		}

		public override ref float TransverseAxis (ref Vector2 coordinate)
		{
			return ref coordinate.y;
		}

		public override float TransverseAxis (Vector2 coordinate)
		{
			return coordinate.y;
		}

		public override void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float scrollbarWidth)
		{
			var parentArea = this.actualParent.Area;
			var parentTopLeft = parentArea.TopLeft;
			var parentBottomRight = parentArea.BottomRight;
			var horizontalAnchor = anchor & (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Left | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right);

			bottomRight.y = topLeft.y + scrollbarWidth;

			if (horizontalAnchor == (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Left | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right))
			{
				float parentLength = parentBottomRight.x - parentTopLeft.x;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap;
				bottomRight.x = topLeft.x + parentLength;
			}
			else if (horizontalAnchor == (uint) LayoutWinProcRegistry.LayoutWinProc.Anchor.Left)
			{
				float scrollbarLength = bottomRight.x - topLeft.x;
				scrollbarLength = scrollbarLength >= 0f ? scrollbarLength : -scrollbarLength;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap;
				bottomRight.x = topLeft.x + scrollbarLength;
			}
			else if (horizontalAnchor != 0)
			{
				float parentLength = parentBottomRight.x - parentTopLeft.x;
				float scrollbarLength = bottomRight.x - topLeft.x;
				scrollbarLength = scrollbarLength >= 0f ? scrollbarLength : -scrollbarLength;
				float scrollbarOffset = parentLength - scrollbarLength;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap + scrollbarOffset;
				bottomRight.x = topLeft.x + scrollbarLength;
			}
		}

		public override bool IsScrollProcScrollbar => this.actualScrollbar.ID == (uint) Window.ScrollProcOrientation.kScrollbarID_Horizontal;

		public override LayoutWinProcRegistry.LayoutWinProc.Anchor ScrollProcAnchor => (
			LayoutWinProcRegistry.LayoutWinProc.Anchor.Left | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom
		);
	}


	public abstract class ScaledSliderMimic
	{
		public const int scaledSliderMimicLayoutID = 0x7085840b;
		public const int actualSliderGlideEffectGroupID = 0x7085850b;
		public const int mimicSliderGlideEffectGroupID = 0x7085860b;
		public static readonly Type buttonType = typeof(Button);

		public Slider actualSlider;
		public WindowBase mimicSlider;
		public Button thumb;
		public Button thumbContainer;
		public WindowBase actualParent;
		public float thumbFirstGrabbedAt = float.NaN;

		public abstract ResourceKey LayoutResourceKey {get;}

		private static ScaledSliderMimic MakeScaledSliderMimic (Slider actualSlider)
		{
			if (actualSlider.Orientation == Slider.SliderOrientation.Vertical)
			{
				return new ScaledVerticalSliderMimic{actualSlider = actualSlider};
			}
			else
			{
				return new ScaledHorizontalSliderMimic{actualSlider = actualSlider};
			}
		}

		public static ScaledSliderMimic GlomOntoSlider (Slider slider)
		{
			var child = slider.GetChildByID(scaledSliderMimicLayoutID, false);

			if (child as object != null)
			{
				ScaledSliderMimic alreadyInitialisedMimic = MakeScaledSliderMimic(slider);
				alreadyInitialisedMimic.mimicSlider = child;
				alreadyInitialisedMimic.InitialiseWindowReferences();

				return alreadyInitialisedMimic;
			}

			var mimic = MakeScaledSliderMimic(slider);
			var mimicSlider = UIManager.LoadLayoutAndAddToWindow(mimic.LayoutResourceKey, slider).GetWindowByExportID(scaledSliderMimicLayoutID);
			mimic.mimicSlider = mimicSlider;
			mimic.InitialiseWindowReferences();
			mimic.GlomOntoSlider();
			return mimic;
		}

		public static void ScrapeOffSlider (Slider slider)
		{
			var mimicSlider = slider.GetChildByID(scaledSliderMimicLayoutID, false);

			if (mimicSlider as object == null)
			{
				return;
			}

			var mimic = MakeScaledSliderMimic(slider);
			mimic.mimicSlider = mimicSlider;
			mimic.InitialiseWindowReferences();
			mimic.DetachEvents();
			mimic.ShowActualSlider();
			mimic.DisposeOfMimic();
		}

		private void GlomOntoSlider ()
		{
			this.MimicAppearanceOfActualSlider();
			var thumbContainerArea = this.MimicAreaOfActualSlider(this.actualSlider.Area);
			this.thumb.Area = this.AreaForThumb(thumbContainerArea, this.actualSlider.Value);
			this.HideActualSlider();
			this.AttachEvents();

			var actualSliderWinHandle = this.actualSlider.WinHandle;
			var actualEventData = EventRegistrationChangeEvents.UIEventRegistryForWinHandle(actualSliderWinHandle);

			if (actualEventData as object != null)
			{
				foreach (var eventType in actualEventData.EventTypesAndCallbacks.Keys)
				{
					this.HandleEventRegistrationChangeForActualSlider(actualSliderWinHandle, eventType, unchecked((uint) UIEventRegistrationChangeType.EventRegistered));
				}
			}
		}

		public abstract float MainAxis (Vector2 coordinate);
		public abstract ref float MainAxis (ref Vector2 coordinate);

		public abstract ref float TransverseAxis (ref Vector2 coordinate);
		public abstract float TransverseAxis (Vector2 coordinate);

		public abstract void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float sliderWidth);

		public void DisposeOfMimic ()
		{
			this.actualSlider.RemoveChild(this.mimicSlider);

			var effectList = this.mimicSlider.EffectList;
			var effectIndex = effectList.Count;

			while (effectIndex-- > 0)
			{
				var effect = effectList[effectIndex] as EffectBase;

				effectList.Remove(effect);
				effect.Dispose();
			}

			this.thumb.Dispose();
			this.thumbContainer.Dispose();
			this.mimicSlider.Dispose();
			this.actualParent = null;
		}

		private void MimicAppearanceOfActualSlider ()
		{
			var drawable = this.actualSlider.Drawable;

			if (drawable is MultiDrawable multiDrawable)
			{
				CopySliderComponentDrawable(multiDrawable[(uint) Slider.SliderComponents.Thumb], this.thumb.Drawable);
				CopySliderComponentDrawable(multiDrawable[(uint) Slider.SliderComponents.ThumbContainer], this.thumbContainer.Drawable);
			}

			var soundGroup = this.actualSlider.SoundGroup;

			this.thumb.SoundGroup = soundGroup;
			this.thumbContainer.SoundGroup = soundGroup;
		}

		private static void CopySliderComponentDrawable (DrawableBase source, DrawableBase destination)
		{
			DrawableHandling.CopyDrawableToDrawable(source, destination);
		}

		public Rect MimicAreaOfActualSlider (Rect actualArea)
		{
			var uiScale = TinyUIFixForTS3Integration.getUIScale();

			var thumbDimensions = ButtonHandling.AutoSizeThenScaleDimensions(this.thumb, uiScale);
			var thumbContainerDimensions = ButtonHandling.AutoSize(this.thumbContainer);

			var topLeft = actualArea.TopLeft;
			var bottomRight = actualArea.BottomRight;

			float thumbContainerWidth = this.TransverseAxis(thumbContainerDimensions);

			if (!(this.thumbContainer.Drawable is ImageDrawable))
			{
				thumbContainerWidth *= uiScale;
			}

			float thumbWidth = this.TransverseAxis(thumbDimensions);

			LayoutWinProcRegistry.LayoutWinProc layoutWinProc = default;

			if (LayoutWinProcRegistry.LookupForWindow(this.actualSlider, ref layoutWinProc))
			{
				this.AdjustAreaForAnchor(ref topLeft, ref bottomRight, layoutWinProc.anchor, thumbWidth);
			}

			this.mimicSlider.Area = new Rect(new Vector2(0f, 0f), new Vector2(bottomRight.x - topLeft.x, bottomRight.y - topLeft.y));

			var areaWidth = this.TransverseAxis(bottomRight) - this.TransverseAxis(topLeft);
			float widthOffset = (areaWidth - thumbContainerWidth) * 0.5f;

			var thumbContainerLength = this.MainAxis(bottomRight) - this.MainAxis(topLeft);

			this.TransverseAxis(ref topLeft) = widthOffset;
			this.MainAxis(ref topLeft) = 0f;
			this.TransverseAxis(ref bottomRight) = widthOffset + thumbContainerWidth;
			this.MainAxis(ref bottomRight) = thumbContainerLength;

			var thumbContainerArea = new Rect(topLeft, bottomRight);
			this.thumbContainer.Area = thumbContainerArea;

			this.MainAxis(ref bottomRight) = this.MainAxis(thumbDimensions);
			var thumbTransverseMiddle = widthOffset + thumbContainerWidth * 0.5f;
			var halfThumbWidth = thumbWidth * 0.5f;
			this.TransverseAxis(ref topLeft) = thumbTransverseMiddle - halfThumbWidth;
			this.TransverseAxis(ref bottomRight) = thumbTransverseMiddle + halfThumbWidth;

			this.thumb.Area = new Rect(topLeft, bottomRight);

			return thumbContainerArea;
		}

		public Rect AreaForThumb (Rect thumbContainerArea, int value)
		{
			var topLeft = thumbContainerArea.TopLeft;
			var bottomRight = thumbContainerArea.BottomRight;
			float length = this.MainAxis(thumbContainerArea.BottomRight) - this.MainAxis(thumbContainerArea.TopLeft);

			var thumbArea = this.thumb.Area;
			var thumbTopLeft = thumbArea.TopLeft;
			var thumbBottomRight = thumbArea.BottomRight;
			var thumbLength = this.MainAxis(thumbBottomRight) - this.MainAxis(thumbTopLeft);

			var minValue = this.actualSlider.MinValue;
			float valueRange = this.actualSlider.MaxValue - minValue;
			float startOffset = ((float) (value - minValue) / valueRange) * (length - thumbLength);

			float start = this.MainAxis(topLeft) + startOffset;
			this.MainAxis(ref thumbTopLeft) = start;
			this.MainAxis(ref thumbBottomRight) = start + thumbLength;

			return new Rect(thumbTopLeft, thumbBottomRight);
		}

		public static int ValueForThumb (float thumbContainerLength, float thumbOffset, float thumbLength, int minValue, int maxValue)
		{
			float movementRange = thumbContainerLength - thumbLength;
			float valueRange = maxValue - minValue;
			int value = (int) Math.Round((thumbOffset / movementRange) * valueRange) + minValue;
			return value <= maxValue ? value : maxValue;
		}

		public void HideActualSlider ()
		{
			var uiManager = UIManager.gUIMgr;
			var actualSliderWinHandle = this.actualSlider.WinHandle;

			var hideActual = new GlideEffect();
			hideActual.Offset = new Vector2(2097152f, 0f);
			hideActual.Duration = 0f;
			hideActual.TriggerType = EffectBase.TriggerTypes.Manual;
			hideActual.GroupID = actualSliderGlideEffectGroupID;
			uiManager.EffectListGeneric(actualSliderWinHandle, (uint) WindowBase.EffectListGenericID.kEffectListAdd, 0, hideActual.EffectHandle);
			hideActual.TriggerEffect(false);

			for (uint index = 0;; ++index)
			{
				var child = uiManager.GetChildByIndex(actualSliderWinHandle, index);
				if (child == 0) break;

				var showChild = new GlideEffect();
				showChild.Offset = new Vector2(-2097152f, 0f);
				showChild.Duration = 0f;
				showChild.TriggerType = EffectBase.TriggerTypes.Manual;
				showChild.GroupID = mimicSliderGlideEffectGroupID;
				uiManager.EffectListGeneric(child, (uint) WindowBase.EffectListGenericID.kEffectListAdd, 0, showChild.EffectHandle);
				showChild.TriggerEffect(false);
			}
		}

		public void ShowActualSlider ()
		{
			var uiManager = UIManager.gUIMgr;
			var actualSliderWinHandle = this.actualSlider.WinHandle;

			var effectIndex = uiManager.EffectListGeneric(actualSliderWinHandle, (uint) WindowBase.EffectListGenericID.kEffectListCount, 0, 0);

			while (effectIndex-- > 0)
			{
				var effect = unchecked((uint) uiManager.EffectListGeneric(actualSliderWinHandle, (uint) WindowBase.EffectListGenericID.kEffectListGetValue, effectIndex, 0));

				if (UIManager.GetUInt32Property(effect, (uint) EffectBase.PropertyID.kBiStateEffectPropGroupID) == actualSliderGlideEffectGroupID)
				{
					uiManager.EffectListGeneric(actualSliderWinHandle, (uint) WindowBase.EffectListGenericID.kEffectListRemove, 0, effect);
					uiManager.DestroyEffect(effect);
				}
			}

			for (uint index = 0;; ++index)
			{
				var child = uiManager.GetChildByIndex(actualSliderWinHandle, index);
				if (child == 0) break;

				effectIndex = uiManager.EffectListGeneric(child, (uint) WindowBase.EffectListGenericID.kEffectListCount, 0, 0);

				while (effectIndex-- > 0)
				{
					var effect = unchecked((uint) uiManager.EffectListGeneric(child, (uint) WindowBase.EffectListGenericID.kEffectListGetValue, effectIndex, 0));

					if (UIManager.GetUInt32Property(effect, (uint) EffectBase.PropertyID.kBiStateEffectPropGroupID) == mimicSliderGlideEffectGroupID)
					{
						uiManager.EffectListGeneric(child, (uint) WindowBase.EffectListGenericID.kEffectListRemove, 0, effect);
						uiManager.DestroyEffect(effect);
					}
				}
			}
		}

		public void InitialiseWindowReferences ()
		{
			var uiManager = UIManager.gUIMgr;
			var mimicSliderHandle = this.mimicSlider.WinHandle;

			var stdDrawableThumb = uiManager.GetChildByID(mimicSliderHandle, 4, false);
			var stdDrawableThumbContainer = uiManager.GetChildByID(mimicSliderHandle, 5, false);
			var imageDrawableThumb = uiManager.GetChildByID(mimicSliderHandle, 6, false);
			var imageDrawableThumbContainer = uiManager.GetChildByID(mimicSliderHandle, 7, false);

			uint thumbHandle = stdDrawableThumb;
			uint thumbContainerHandle = stdDrawableThumbContainer;
			uint unusedThumbHandle = imageDrawableThumb;
			uint unusedThumbContainerHandle = imageDrawableThumbContainer;

			if (this.actualSlider.Drawable is MultiDrawable multiDrawable)
			{
				if (multiDrawable[(uint) Slider.SliderComponents.Thumb] is ImageDrawable)
				{
					thumbHandle = imageDrawableThumb;
					unusedThumbHandle = stdDrawableThumb;
				}

				if (multiDrawable[(uint) Slider.SliderComponents.ThumbContainer] is ImageDrawable)
				{
					thumbContainerHandle = imageDrawableThumbContainer;
					unusedThumbContainerHandle = stdDrawableThumbContainer;
				}
			}

			//uiManager.RemoveChild(mimicSliderHandle, unusedThumbHandle);
			//uiManager.RemoveChild(mimicSliderHandle, unusedThumbContainerHandle);

			UIManager.SetFlagProperty(unusedThumbHandle, (uint) WindowBase.PropertyID.kPropWindowFlags, (uint) WindowBase.WindowFlags.kMaskWindowFlagsVisible, false);
			UIManager.SetFlagProperty(unusedThumbContainerHandle, (uint) WindowBase.PropertyID.kPropWindowFlags, (uint) WindowBase.WindowFlags.kMaskWindowFlagsVisible, false);
			UIManager.SetFlagProperty(thumbHandle, (uint) WindowBase.PropertyID.kPropWindowFlags, (uint) WindowBase.WindowFlags.kMaskWindowFlagsVisible, true);
			UIManager.SetFlagProperty(thumbContainerHandle, (uint) WindowBase.PropertyID.kPropWindowFlags, (uint) WindowBase.WindowFlags.kMaskWindowFlagsVisible, true);

			this.thumb = UIManager.RetrieveWindowInstance(thumbHandle, buttonType) as Button;
			this.thumbContainer = UIManager.RetrieveWindowInstance(thumbContainerHandle, buttonType) as Button;
			this.actualParent = this.actualSlider.Parent;
		}

		public void AttachEvents ()
		{
			this.AttachEventsToThumb();
			this.AttachEventsToThumbContainer();
			this.AttachEventsToActualSlider();
		}

		public void DetachEvents ()
		{
			this.DetachEventsFromThumb();
			this.DetachEventsFromThumbContainer();
			this.DetachEventsFromActualSlider();
		}

		public void AttachEventsToThumb ()
		{
			this.thumb.MouseDown += this.HandleThumbMouseDown;
			this.thumb.MouseUp += this.HandleThumbMouseUp;
		}

		public void DetachEventsFromThumb ()
		{
			this.thumb.MouseDown -= this.HandleThumbMouseDown;
			this.thumb.MouseUp -= this.HandleThumbMouseUp;
		}

		public void AttachEventsToThumbContainer ()
		{
			this.thumbContainer.MouseDown += this.HandleThumbContainerMouseDown;
			this.thumbContainer.MouseUp += this.HandleThumbContainerMouseUp;
		}

		public void DetachEventsFromThumbContainer ()
		{
			this.thumbContainer.MouseDown -= this.HandleThumbContainerMouseDown;
			this.thumbContainer.MouseUp -= this.HandleThumbContainerMouseUp;
		}

		public void AttachEventsToActualSlider ()
		{
			this.actualSlider.Detach += this.HandleDetachOfActualSlider;
			this.actualSlider.Attach += this.HandleAttachOfActualSlider;
			this.actualSlider.AreaChange += this.MimicAreaOfActualSliderOnChangeOfArea;
			this.actualSlider.VisibilityChange += this.MimicVisibilityOfActualSliderOnChangeOfVisibility;
			this.actualSlider.SliderValueChange += this.HandleSliderValueChange;
			EventRegistrationChangeEvents.registerEventRegistrationChangeEventHandler(this.actualSlider.WinHandle, this.HandleEventRegistrationChangeForActualSlider);
		}

		public void DetachEventsFromActualSlider ()
		{
			this.actualSlider.Detach -= this.HandleDetachOfActualSlider;
			this.actualSlider.Attach -= this.HandleAttachOfActualSlider;
			this.actualSlider.AreaChange -= this.MimicAreaOfActualSliderOnChangeOfArea;
			this.actualSlider.VisibilityChange -= this.MimicVisibilityOfActualSliderOnChangeOfVisibility;
			this.actualSlider.SliderValueChange -= this.HandleSliderValueChange;
			EventRegistrationChangeEvents.deregisterEventRegistrationChangeEventHandler(this.actualSlider.WinHandle, this.HandleEventRegistrationChangeForActualSlider);
		}

		public void StartChangingSliderValue ()
		{
			this.actualSlider.SliderValueChange -= this.HandleSliderValueChange;
			this.actualSlider.AreaChange -= this.MimicAreaOfActualSliderOnChangeOfArea;
		}

		public void StopChangingSliderValue ()
		{
			this.actualSlider.SliderValueChange += this.HandleSliderValueChange;
			this.actualSlider.AreaChange += this.MimicAreaOfActualSliderOnChangeOfArea;
		}

		public void HandleEventRegistrationChangeForActualSlider (uint windowHandle, uint eventType, uint eventChangeType)
		{
			if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.AllEventsDeregistered))
			{
				for (uint index = 2; index-- > 0;)
				{
					var control = index == 0 ? this.thumb : this.thumbContainer;

					control.MouseDown -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.MouseUp -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.MouseMove -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.MouseWheel -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.HitTest -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.TriggerDown -= this.ForwardUIEventToActualSlider;
					control.TriggerUp -= this.ForwardUIEventToActualSlider;
					control.FocusAcquired -= this.ForwardUIEventToActualSlider;
					control.FocusLost -= this.ForwardUIEventToActualSlider;
					control.DragEnter -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.DragLeave -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.DragOver -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.DragDrop -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.DragEnd -= this.ForwardUIEventWithMousePositionToActualSlider;
					control.DragQueryContinue -= this.ForwardUIEventToActualSlider;
				}

				return;
			}


			for (uint index = 2; index-- > 0;)
			{
				var control = index == 0 ? this.thumb : this.thumbContainer;

				switch (eventType)
				{
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseDown): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseDown += this.ForwardUIEventWithMousePositionToActualSlider; else control.MouseDown -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseUp): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseUp += this.ForwardUIEventWithMousePositionToActualSlider; else control.MouseUp -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseMove): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseMove += this.ForwardUIEventWithMousePositionToActualSlider; else control.MouseMove -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseMouseWheel): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.MouseWheel += this.ForwardUIEventWithMousePositionToActualSlider; else control.MouseWheel -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseHitTest): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.HitTest += this.ForwardUIEventWithMousePositionToActualSlider; else control.HitTest -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseTriggerDown): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.TriggerDown += this.ForwardUIEventToActualSlider; else control.TriggerDown -= this.ForwardUIEventToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseTriggerUp): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.TriggerUp += this.ForwardUIEventToActualSlider; else control.TriggerUp -= this.ForwardUIEventToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseFocusAcquired): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.FocusAcquired += this.ForwardUIEventToActualSlider; else control.FocusAcquired -= this.ForwardUIEventToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseFocusLost): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.FocusLost += this.ForwardUIEventToActualSlider; else control.FocusLost -= this.ForwardUIEventToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragEnter): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragEnter += this.ForwardUIEventWithMousePositionToActualSlider; else control.DragEnter -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragLeave): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragLeave += this.ForwardUIEventWithMousePositionToActualSlider; else control.DragLeave -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragOver): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragOver += this.ForwardUIEventWithMousePositionToActualSlider; else control.DragOver -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragDrop): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragDrop += this.ForwardUIEventWithMousePositionToActualSlider; else control.DragDrop -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragEnd): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragEnd += this.ForwardUIEventWithMousePositionToActualSlider; else control.DragEnd -= this.ForwardUIEventWithMousePositionToActualSlider; break;
				case unchecked((uint) WindowBase.WindowBaseEvents.kEventWindowBaseDragQueryContinue): if (eventChangeType == unchecked((uint) UIEventRegistrationChangeType.EventRegistered)) control.DragQueryContinue += this.ForwardUIEventToActualSlider; else control.DragQueryContinue -= this.ForwardUIEventToActualSlider; break;
				}
			}
		}

		public void HandleAttachOfActualSlider (WindowBase sender, UIEventArgs eventArgs)
		{
			this.actualParent = this.actualSlider.Parent;
		}

		public void HandleDetachOfActualSlider (WindowBase sender, UIEventArgs eventArgs)
		{
			this.actualParent = null;
		}

		public void MimicAreaOfActualSliderOnChangeOfArea (WindowBase sender, UIAreaChangeEventArgs eventArgs)
		{
			this.MimicAppearanceOfActualSlider();
			var thumbContainerArea = this.MimicAreaOfActualSlider(eventArgs.NewArea);
			this.thumb.Area = this.AreaForThumb(thumbContainerArea, this.actualSlider.Value);
		}

		public void MimicVisibilityOfActualSliderOnChangeOfVisibility (WindowBase sender, UIVisibilityChangeEventArgs eventArgs)
		{
			this.mimicSlider.Visible = eventArgs.Visible;
		}

		public void HandleSliderValueChange (WindowBase sender, UIValueChangedEventArgs eventArgs)
		{
			this.thumb.Area = this.AreaForThumb(this.thumbContainer.Area, eventArgs.NewValue);
		}

		/* `at` must be relative to the top-left of the thumb. */
		public void GrabThumb (Vector2 at)
		{
			this.StartChangingSliderValue();

			this.thumbFirstGrabbedAt = this.MainAxis(at);
		}

		public void ReleaseThumb ()
		{
			this.StopChangingSliderValue();

			this.thumbFirstGrabbedAt = float.NaN;
		}

		/* `to` must be relative to the top-left of the thumb. */
		public void MoveThumb (Vector2 to)
		{
			var uiScale = TinyUIFixForTS3Integration.getUIScale();
			var thumbArea = this.thumb.Area;
			var topLeft = thumbArea.TopLeft;
			var bottomRight = thumbArea.BottomRight;
			var thumbStart = this.MainAxis(topLeft);
			var thumbLength = this.MainAxis(bottomRight) - thumbStart;
			var thumbMiddle = thumbStart + thumbLength;

			float adjustedStart = this.MainAxis(this.mimicSlider.ScreenToWindow(this.thumb.WindowToScreen(to))) - this.thumbFirstGrabbedAt;
			float delta = adjustedStart - thumbMiddle;
			float adjustedEnd = thumbMiddle + delta;

			var thumbContainerArea = this.thumbContainer.Area;
			float topBound = this.MainAxis(thumbContainerArea.TopLeft);
			float bottomBound = this.MainAxis(thumbContainerArea.BottomRight);
			float thumbContainerLength = bottomBound - topBound;

			float topExcess = topBound - adjustedStart;
			topExcess = topExcess <= 0 ? 0 : topExcess;
			float bottomExcess = adjustedEnd - bottomBound;
			bottomExcess = bottomExcess <= 0 ? 0 : bottomExcess;
			float excess = topExcess - bottomExcess;

			var top = adjustedStart + excess;

			int value = ValueForThumb(
				thumbContainerLength,
				top - topBound,
				thumbLength,
				this.actualSlider.MinValue,
				this.actualSlider.MaxValue
			);
			int activeValue = this.actualSlider.Value;

			if (value != activeValue)
			{
				this.thumb.Area = this.AreaForThumb(thumbContainerArea, value);

				this.actualSlider.Value = value;
				this.MimicSliderValueChangeEvent(activeValue, value);
			}
		}

		public void HandleThumbMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.SetCaptureTarget(InputContext.kICMouse, this.thumb);
				this.thumb.MouseMove += this.HandleThumbMouseMove;
				this.GrabThumb(eventArgs.MousePosition);
				eventArgs.Handled = true;
			}
		}

		public void HandleThumbMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				this.thumb.MouseMove -= this.HandleThumbMouseMove;
				UIManager.ReleaseCapture(InputContext.kICMouse, this.thumb);
				this.ReleaseThumb();
				eventArgs.Handled = true;
			}
		}

		public void HandleThumbMouseMove (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			#pragma warning disable CS1718
			if (this.thumbFirstGrabbedAt == this.thumbFirstGrabbedAt)
			#pragma warning disable CS1718
			{
				this.MoveThumb(eventArgs.MousePosition);
				eventArgs.Handled = true;
			}
		}

		public void HandleThumbContainerMouseDown (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.SetCaptureTarget(InputContext.kICMouse, this.thumbContainer);

				this.StartChangingSliderValue();

				var thumbContainerArea = this.thumbContainer.Area;
				var thumbContainerStart = this.MainAxis(thumbContainerArea.TopLeft);
				var thumbContainerLength = this.MainAxis(thumbContainerArea.BottomRight) - thumbContainerStart;
				var thumbArea = this.thumb.Area;
				var thumbLength = this.MainAxis(thumbArea.BottomRight) - this.MainAxis(thumbArea.TopLeft);
				var thumbOffset = this.MainAxis(eventArgs.MousePosition);

				thumbOffset -= thumbLength * 0.5f;

				float start = thumbContainerStart;
				float end = thumbContainerStart + (thumbContainerLength - thumbLength);

				if (thumbOffset < start)
				{
					thumbOffset = start;
				}
				else if (thumbOffset > end)
				{
					thumbOffset = end;
				}

				thumbOffset -= start;

				int value = ValueForThumb(
					thumbContainerLength,
					thumbOffset,
					thumbLength,
					this.actualSlider.MinValue,
					this.actualSlider.MaxValue
				);
				int activeValue = this.actualSlider.Value;

				if (value != activeValue)
				{
					this.thumb.Area = this.AreaForThumb(thumbContainerArea, value);

					this.actualSlider.Value = value;
					this.MimicSliderValueChangeEvent(activeValue, value);
				}

				eventArgs.Handled = true;
			}
		}

		public void HandleThumbContainerMouseUp (WindowBase sender, UIMouseEventArgs eventArgs)
		{
			if ((eventArgs.MouseKey & MouseKeys.kMouseLeft) == MouseKeys.kMouseLeft)
			{
				UIManager.ReleaseCapture(InputContext.kICMouse, this.thumbContainer);

				this.StopChangingSliderValue();

				eventArgs.Handled = true;
			}
		}

		public void MimicSliderValueChangeEvent (int oldValue, int newValue)
		{
			bool result = false;

			UIManager.ProcessEvent(
				this.actualSlider.WinHandle,
				unchecked((uint) Slider.SliderEvents.kEventSliderValueChanged),
				this.actualSlider,
				this.actualParent,
				unchecked((int) this.actualSlider.ID),
				ref oldValue,
				newValue,
				0,
				0,
				0,
				0,
				ref result,
				null
			);
		}

		public void ForwardUIEventToActualSlider (WindowBase sender, UIEventArgs eventArgs)
		{
			UIManager.ProcessEvent(
				this.actualSlider.WinHandle,
				eventArgs.mType,
				this.actualSlider,
				this.actualSlider,
				eventArgs.mArg1,
				ref eventArgs.mArg2,
				eventArgs.mArg3,
				eventArgs.mF1,
				eventArgs.mF2,
				eventArgs.mF3,
				eventArgs.mF4,
				ref eventArgs.mResult,
				eventArgs.mText
			);
		}

		public void ForwardUIEventWithMousePositionToActualSlider (WindowBase sender, UIEventArgs eventArgs)
		{
			var mousePosition = new Vector2(eventArgs.mF1, eventArgs.mF2);
			mousePosition = this.mimicSlider.ScreenToWindow(sender.WindowToScreen(mousePosition));
			this.TransverseAxis(ref mousePosition) /= TinyUIFixForTS3Integration.getUIScale();

			UIManager.ProcessEvent(
				this.actualSlider.WinHandle,
				eventArgs.mType,
				this.actualSlider,
				this.actualSlider,
				eventArgs.mArg1,
				ref eventArgs.mArg2,
				eventArgs.mArg3,
				mousePosition.x,
				mousePosition.y,
				eventArgs.mF3,
				eventArgs.mF4,
				ref eventArgs.mResult,
				eventArgs.mText
			);
		}
	}

	public class ScaledVerticalSliderMimic : ScaledSliderMimic
	{
		public override ResourceKey LayoutResourceKey => new ResourceKey(0x92e4874f8b9f3d39, 0x025c95b6, 0x84857051);

		public override ref float MainAxis (ref Vector2 coordinate)
		{
			return ref coordinate.y;
		}

		public override float MainAxis (Vector2 coordinate)
		{
			return coordinate.y;
		}

		public override ref float TransverseAxis (ref Vector2 coordinate)
		{
			return ref coordinate.x;
		}

		public override float TransverseAxis (Vector2 coordinate)
		{
			return coordinate.x;
		}

		public override void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float sliderWidth)
		{
			var parentArea = this.actualParent.Area;
			var parentTopLeft = parentArea.TopLeft;
			var parentBottomRight = parentArea.BottomRight;
			var verticalAnchor = anchor & (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Top | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom);

			topLeft.x = 0f;
			bottomRight.x = sliderWidth;

			if (verticalAnchor == (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Top | LayoutWinProcRegistry.LayoutWinProc.Anchor.Bottom))
			{
				float parentLength = parentBottomRight.y - parentTopLeft.y;
				float sliderLength = bottomRight.y - topLeft.y;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float sliderOffset = (parentLength - sliderLength) * 0.5f;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap + sliderOffset;
				bottomRight.y = topLeft.y + sliderLength;
			}
			else if (verticalAnchor == (uint) LayoutWinProcRegistry.LayoutWinProc.Anchor.Top)
			{
				float sliderLength = bottomRight.y - topLeft.y;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap;
				bottomRight.y = topLeft.y + sliderLength;
			}
			else if (verticalAnchor != 0)
			{
				float parentLength = parentBottomRight.y - parentTopLeft.y;
				float sliderLength = bottomRight.y - topLeft.y;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float sliderOffset = parentLength - sliderLength;
				float leadingGap = topLeft.y;
				topLeft.y = -leadingGap + sliderOffset;
				bottomRight.y = topLeft.y + sliderLength;
			}
		}
	}

	public class ScaledHorizontalSliderMimic : ScaledSliderMimic
	{
		public override ResourceKey LayoutResourceKey => new ResourceKey(0xb30738093abb4eab, 0x025c95b6, 0x84857051);

		public override ref float MainAxis (ref Vector2 coordinate)
		{
			return ref coordinate.x;
		}

		public override float MainAxis (Vector2 coordinate)
		{
			return coordinate.x;
		}

		public override ref float TransverseAxis (ref Vector2 coordinate)
		{
			return ref coordinate.y;
		}

		public override float TransverseAxis (Vector2 coordinate)
		{
			return coordinate.y;
		}

		public override void AdjustAreaForAnchor (ref Vector2 topLeft, ref Vector2 bottomRight, byte anchor, float sliderWidth)
		{
			var parentArea = this.actualParent.Area;
			var parentTopLeft = parentArea.TopLeft;
			var parentBottomRight = parentArea.BottomRight;
			var horizontalAnchor = anchor & (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Left | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right);

			topLeft.y = 0f;
			bottomRight.y = sliderWidth;

			if (horizontalAnchor == (uint) (LayoutWinProcRegistry.LayoutWinProc.Anchor.Left | LayoutWinProcRegistry.LayoutWinProc.Anchor.Right))
			{
				float parentLength = parentBottomRight.x - parentTopLeft.x;
				float sliderLength = bottomRight.x - topLeft.x;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float sliderOffset = (parentLength - sliderLength) * 0.5f;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap + sliderOffset;
				bottomRight.x = topLeft.x + sliderLength;
			}
			else if (horizontalAnchor == (uint) LayoutWinProcRegistry.LayoutWinProc.Anchor.Left)
			{
				float sliderLength = bottomRight.x - topLeft.x;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap;
				bottomRight.x = topLeft.x + sliderLength;
			}
			else if (horizontalAnchor != 0)
			{
				float parentLength = parentBottomRight.x - parentTopLeft.x;
				float sliderLength = bottomRight.x - topLeft.x;
				sliderLength = sliderLength >= 0f ? sliderLength : -sliderLength;
				float sliderOffset = parentLength - sliderLength;
				float leadingGap = topLeft.x;
				topLeft.x = -leadingGap + sliderOffset;
				bottomRight.x = topLeft.x + sliderLength;
			}
		}
	}
}

