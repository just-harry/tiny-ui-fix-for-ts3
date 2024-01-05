
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
using System.Globalization;
using System.Linq;
using System.IO;
using System.Numerics;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml;

namespace TinyUIFixForTS3Patcher
{
	public static class Parsing
	{
		public static readonly NumberFormatInfo floatFormat = new NumberFormatInfo();
		public static readonly NumberFormatInfo integerFormat = new NumberFormatInfo();
	}

	public static class LayoutScaler
	{
		public const string floatFormatString = "{0:F9}";
		public const string intHexFormatString = "0x{0:x8}";
		public const string intDecimalFormatString = "{0:d}";

		[ThreadStatic] static StringBuilder stringBuilder;

		public static void InitialiseForCurrentThread ()
		{
			stringBuilder = new StringBuilder(60);
		}

		public static Vector4 AreaFromString (string text)
		{
			var values = text.Split(',');

			return new Vector4(
				float.Parse(values[0], Parsing.floatFormat),
				float.Parse(values[1], Parsing.floatFormat),
				float.Parse(values[3], Parsing.floatFormat),
				float.Parse(values[2], Parsing.floatFormat)
			);
		}

		public static string AreaToString (Vector4 area)
		{
			var builder = stringBuilder;
			builder.Clear();
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, area.X);
			builder.Append(',');
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, area.Y);
			builder.Append(',');
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, area.W);
			builder.Append(',');
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, area.Z);

			return builder.ToString();
		}

		public static Vector2 PointFromString (string text)
		{
			var values = text.Split(',');

			return new Vector2(
				float.Parse(values[0], Parsing.floatFormat),
				float.Parse(values[1], Parsing.floatFormat)
			);
		}

		public static string PointToString (Vector2 point)
		{
			var builder = stringBuilder;
			builder.Clear();
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, point.X);
			builder.Append(',');
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, point.Y);

			return builder.ToString();
		}

		public static float ValueFromString (string text)
		{
			return float.Parse(text, Parsing.floatFormat);
		}

		public static string ValueToString (float value)
		{
			var builder = stringBuilder;
			builder.Clear();
			builder.AppendFormat(Parsing.floatFormat, floatFormatString, value);

			return builder.ToString();
		}

		public static Vector4 ScaleAreaBy (Vector4 area, float multiplier)
		{
			return area * multiplier;
		}

		public static string ScaleAreaStringBy (string area, float multiplier)
		{
			return AreaToString(AreaFromString(area) * multiplier);
		}

		public static Vector2 ScalePointBy (Vector2 point, float multiplier)
		{
			return point * multiplier;
		}

		public static string ScalePointStringBy (string point, float multiplier)
		{
			return PointToString(PointFromString(point) * multiplier);
		}

		public static float ScaleValueBy (float value, float multiplier)
		{
			return value * multiplier;
		}

		public static string ScaleValueStringBy (string value, float multiplier)
		{
			return ValueToString(ValueFromString(value) * multiplier);
		}

		public struct LayoutWinProc
		{
			public enum Type : byte
			{
				SimpleLayout,
				HudLayout
			}

			public Type type;
			public byte anchor;
			public Vector2 dimensions;
		}

		public struct ControlIDChain
		{
			public uint[] controlIDs;
		}

		public class ScaledLayoutResult
		{
			public Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>> scrollbarLayoutWinProcsByControlID;
			public Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>> sliderLayoutWinProcsByControlID;

			public ScaledLayoutResult ()
			{
				this.scrollbarLayoutWinProcsByControlID = new Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>>(0);
				this.sliderLayoutWinProcsByControlID = new Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>>(0);
			}
		}

		public static ScaledLayoutResult ScaleLayoutBy (XmlDocument xml, float multiplier, IEnumerable<ExtraScaler> extraScalers)
		{
			if (stringBuilder == null)
			{
				InitialiseForCurrentThread();
			}

			var state = new NodeScalingState(extraScalers);

			foreach (XmlNode child in xml) {ScaleNodeBy(child, multiplier, ref state);}

			return state.result;
		}

		public delegate bool ExtraScaler (XmlNode node, float multiplier, ref NodeScalingState state);

		public struct NodeScalingState
		{
			public IEnumerable<ExtraScaler> extraScalers;
			public ScaledLayoutResult result;
			public List<uint> controlIDChain;
			public State state;

			[Flags]
			public enum State : uint
			{
				None = 0,
				WinProcsForScrollbar = 1 << 0,
				WinProcsForSlider = 1 << 1
			}

			public NodeScalingState (IEnumerable<ExtraScaler> extraScalers)
			{
				this.extraScalers = extraScalers;
				this.result = new ScaledLayoutResult();
				this.controlIDChain = new List<uint>();
				this.state = State.None;
			}
		}

		public static void ScaleNodeBy (XmlNode xml, float multiplier, ref NodeScalingState state)
		{
			if (xml.NodeType != XmlNodeType.Element)
			{
				return;
			}

			if (xml.Name == "object" || xml.Name == "struct")
			{
				XmlNode nodeClass = xml.Attributes.GetNamedItem("cls");

				XmlNode area = null;
				XmlNode children = null;
				XmlNode controlID = null;
				XmlNode winProcs = null;

				if (nodeClass.Value == "Window" || nodeClass.Value == "Sims3CustomWindow")
				{
					XmlNode fillDrawable = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "FillDrawable") {fillDrawable = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					if (fillDrawable != null) {foreach (XmlNode drawable in fillDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}}
				}
				else if (nodeClass.Value == "StdDrawable")
				{
					XmlNode scaleFactor = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "ScaleFactor") {scaleFactor = property;}
					}

					XmlNode scaleFactorValue = scaleFactor.Attributes.GetNamedItem("value");
					scaleFactorValue.Value = ScalePointStringBy(scaleFactorValue.Value, multiplier);
				}
				else if (
					   nodeClass.Value == "Button"
					|| nodeClass.Value == "IconButton"
					|| nodeClass.Value == "Sims3CustomButton"
					|| nodeClass.Value == "Sims3IconButton"
					|| nodeClass.Value == "Sims3Checkbox"
					|| nodeClass.Value == "Sims3RadioButton"
				)
				{
					XmlNode buttonDrawable = null;
					XmlNode buttonFlags = null;
					XmlNode buttonType = null;
					XmlNode captionBorder = null;
					XmlNode captionOffset = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "ButtonDrawable") {buttonDrawable = property;}
						else if (propertyName.Value == "ButtonFlags") {buttonFlags = property;}
						else if (propertyName.Value == "ButtonType") {buttonType = property;}
						else if (propertyName.Value == "CaptionBorder") {captionBorder = property;}
						else if (propertyName.Value == "CaptionOffset") {captionOffset = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode buttonFlagsValue = buttonFlags.Attributes.GetNamedItem("value");
					var buttonFlagsInt = Convert.ToUInt32(buttonFlagsValue.Value, 16);

					stringBuilder.Clear();
					/* The 0b100 button-flag inhibits vertical scaling, similarly the 0b010 flag inhibits horizontal scaling.
					   So, we clear those bits if they're set. */
					stringBuilder.AppendFormat(Parsing.integerFormat, intHexFormatString, buttonFlagsInt & 0xfffffff9);

					buttonFlagsValue.Value = stringBuilder.ToString();

					XmlNode captionOffsetValue = captionOffset.Attributes.GetNamedItem("value");
					captionOffsetValue.Value = ScalePointStringBy(captionOffsetValue.Value, multiplier);

					foreach (XmlNode drawable in buttonDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
					foreach (XmlNode border in captionBorder) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "Borders")
				{
					XmlNode left = null;
					XmlNode top = null;
					XmlNode right = null;
					XmlNode bottom = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Left") {left = property;}
						else if (propertyName.Value == "Top") {top = property;}
						else if (propertyName.Value == "Right") {right = property;}
						else if (propertyName.Value == "Bottom") {bottom = property;}
					}

					XmlNode leftValue = left.Attributes.GetNamedItem("value");
					leftValue.Value = ScaleValueStringBy(leftValue.Value, multiplier);

					XmlNode topValue = top.Attributes.GetNamedItem("value");
					topValue.Value = ScaleValueStringBy(topValue.Value, multiplier);

					XmlNode rightValue = right.Attributes.GetNamedItem("value");
					rightValue.Value = ScaleValueStringBy(rightValue.Value, multiplier);

					XmlNode bottomValue = bottom.Attributes.GetNamedItem("value");
					bottomValue.Value = ScaleValueStringBy(bottomValue.Value, multiplier);
				}
				else if (nodeClass.Value == "ImageDrawable" || nodeClass.Value == "IconDrawable")
				{
					XmlNode scale = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "Scale") {scale = property;}
					}

					XmlNode scaleValue = scale.Attributes.GetNamedItem("value");
					scaleValue.Value = ScaleValueStringBy(scaleValue.Value, multiplier);
				}
				else if (nodeClass.Value == "Text")
				{
					XmlNode fillDrawable = null;
					XmlNode textBorder = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "FillDrawable") {fillDrawable = property;}
						else if (propertyName.Value == "TextBorder") {textBorder = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					if (fillDrawable != null) {foreach (XmlNode drawable in fillDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}}
					foreach (XmlNode border in textBorder) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "Glide")
				{
					XmlNode offset = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "Offset") {offset = property;}
					}

					XmlNode offsetValue = offset.Attributes.GetNamedItem("value");
					offsetValue.Value = ScalePointStringBy(offsetValue.Value, multiplier);
				}
				else if (nodeClass.Value == "Grow")
				{
					XmlNode boundaryChangeRect = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "Boundary Change Rect") {boundaryChangeRect = property;}
					}

					foreach (XmlNode border in boundaryChangeRect) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "HudLayout")
				{
					XmlNode anchor = null;
					XmlNode dimensions = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Anchor") {anchor = property;}
						else if (propertyName.Value == "Dimensions") {dimensions = property;}
					}

					XmlNode dimensionsValue = dimensions.Attributes.GetNamedItem("value");
					var dimensionsValuePoint = ScalePointBy(PointFromString(dimensionsValue.Value), multiplier);
					dimensionsValue.Value = PointToString(dimensionsValuePoint);

					Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>> layoutWinProcs = null;

					     if ((state.state & NodeScalingState.State.WinProcsForScrollbar) != 0) layoutWinProcs = state.result.scrollbarLayoutWinProcsByControlID;
					else if ((state.state & NodeScalingState.State.WinProcsForSlider) != 0) layoutWinProcs = state.result.sliderLayoutWinProcsByControlID;

					if (layoutWinProcs != null)
					{
						XmlNode anchorValue = anchor.Attributes.GetNamedItem("value");
						byte anchorValueInt = byte.Parse(anchorValue.Value, Parsing.integerFormat);

						layoutWinProcs[state.controlIDChain[state.controlIDChain.Count - 1]].Add(
							new ValueTuple<LayoutWinProc, ControlIDChain>(
								new LayoutWinProc{type = LayoutWinProc.Type.HudLayout, anchor = anchorValueInt, dimensions = dimensionsValuePoint},
								new ControlIDChain{controlIDs = state.controlIDChain.ToArray()}
							)
						);
					}
				}
				else if (nodeClass.Value == "SimpleLayout")
				{
					Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>> layoutWinProcs = null;

					     if ((state.state & NodeScalingState.State.WinProcsForScrollbar) != 0) layoutWinProcs = state.result.scrollbarLayoutWinProcsByControlID;
					else if ((state.state & NodeScalingState.State.WinProcsForSlider) != 0) layoutWinProcs = state.result.sliderLayoutWinProcsByControlID;

					if (layoutWinProcs != null)
					{
						XmlNode anchor = null;

						foreach (XmlNode property in xml)
						{
							if (property.NodeType != XmlNodeType.Element) {continue;}

							XmlNode propertyName = property.Attributes.GetNamedItem("name");

							if (propertyName.Value == "Anchor") {anchor = property;}
						}

						XmlNode anchorValue = anchor.Attributes.GetNamedItem("value");
						byte anchorValueInt = byte.Parse(anchorValue.Value, Parsing.integerFormat);

						layoutWinProcs[state.controlIDChain[state.controlIDChain.Count - 1]].Add(
							new ValueTuple<LayoutWinProc, ControlIDChain>(
								new LayoutWinProc{type = LayoutWinProc.Type.SimpleLayout, anchor = anchorValueInt},
								new ControlIDChain{controlIDs = state.controlIDChain.ToArray()}
							)
						);
					}
				}
				else if (
					   nodeClass.Value == "IconButtonMultiDrawable"
					|| nodeClass.Value == "ScrollbarMultiDrawable"
					|| nodeClass.Value == "SliderMultiDrawable"
					|| nodeClass.Value == "ComboBoxMultiDrawable"
					|| nodeClass.Value == "SpinnerMultiDrawable"
				)
				{
					XmlNode drawables = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "Drawables") {drawables = property;}
					}

					foreach (XmlNode drawable in drawables) {ScaleNodeBy(drawable, multiplier, ref state);}
				}
				else if (nodeClass.Value == "TextEdit")
				{
					XmlNode borderWidth = null;
					XmlNode clipBorders = null;
					XmlNode hScrollbarDrawable = null;
					XmlNode vScrollbarDrawable = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "BorderWidth") {borderWidth = property;}
						else if (propertyName.Value == "ClipBorders") {clipBorders = property;}
						else if (propertyName.Value == "HScrollbarDrawable") {hScrollbarDrawable = property;}
						else if (propertyName.Value == "VScrollbarDrawable") {vScrollbarDrawable = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					foreach (XmlNode border in borderWidth) {ScaleNodeBy(border, multiplier, ref state);}
					if (clipBorders != null) {foreach (XmlNode border in clipBorders) {ScaleNodeBy(border, multiplier, ref state);}}
					foreach (XmlNode drawable in hScrollbarDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
					foreach (XmlNode drawable in vScrollbarDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
				}
				else if (nodeClass.Value == "ComboBox" || nodeClass.Value == "Sims3ComboBox")
				{
					XmlNode captionGutters = null;
					XmlNode comboBoxDrawable = null;
					XmlNode gutters = null;
					XmlNode pullDownBackgroundDrawable = null;
					XmlNode pulldownVerticalOffset = null;
					XmlNode scrollbarDrawable = null;
					XmlNode scrollbarOffset = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "CaptionGutters") {captionGutters = property;}
						else if (propertyName.Value == "ComboBoxDrawable") {comboBoxDrawable = property;}
						else if (propertyName.Value == "Gutters") {gutters = property;}
						else if (propertyName.Value == "PullDownBackgroundDrawable") {pullDownBackgroundDrawable = property;}
						else if (propertyName.Value == "PulldownVerticalOffset") {pulldownVerticalOffset = property;}
						else if (propertyName.Value == "ScrollbarDrawable") {scrollbarDrawable = property;}
						else if (propertyName.Value == "ScrollbarOffset") {scrollbarOffset = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode pulldownVerticalOffsetValue = pulldownVerticalOffset.Attributes.GetNamedItem("value");
					pulldownVerticalOffsetValue.Value = ScaleValueStringBy(pulldownVerticalOffsetValue.Value, multiplier);

					foreach (XmlNode border in captionGutters) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode drawable in comboBoxDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
					foreach (XmlNode border in gutters) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode drawable in scrollbarDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
					if (scrollbarOffset != null) {foreach (XmlNode border in scrollbarOffset) {ScaleNodeBy(border, multiplier, ref state);}}
					if (pullDownBackgroundDrawable != null) {foreach (XmlNode drawable in pullDownBackgroundDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}}
				}
				else if (nodeClass.Value == "Dialog" || nodeClass.Value == "Sims3CustomDialog")
				{
					XmlNode clientAreaBorder = null;
					XmlNode closeButtonBorder = null;
					XmlNode closeButtonDrawable = null;
					XmlNode dialogDrawable = null;
					XmlNode maxHeight = null;
					XmlNode maxWidth = null;
					XmlNode minHeight = null;
					XmlNode minWidth = null;
					XmlNode titleTextBorder = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "ClientAreaBorder") {clientAreaBorder = property;}
						else if (propertyName.Value == "CloseButtonBorder") {closeButtonBorder = property;}
						else if (propertyName.Value == "CloseButtonDrawable") {closeButtonDrawable = property;}
						else if (propertyName.Value == "DialogDrawable") {dialogDrawable = property;}
						else if (propertyName.Value == "MaxHeight") {maxHeight = property;}
						else if (propertyName.Value == "MaxWidth") {maxWidth = property;}
						else if (propertyName.Value == "MinHeight") {minHeight = property;}
						else if (propertyName.Value == "MinWidth") {minWidth = property;}
						else if (propertyName.Value == "TitleTextBorder") {titleTextBorder = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode maxHeightValue = maxHeight.Attributes.GetNamedItem("value");
					maxHeightValue.Value = ScaleValueStringBy(maxHeightValue.Value, multiplier);
					XmlNode maxWidthValue = maxWidth.Attributes.GetNamedItem("value");
					maxWidthValue.Value = ScaleValueStringBy(maxWidthValue.Value, multiplier);
					XmlNode minHeightValue = minHeight.Attributes.GetNamedItem("value");
					minHeightValue.Value = ScaleValueStringBy(minHeightValue.Value, multiplier);
					XmlNode minWidthValue = minWidth.Attributes.GetNamedItem("value");
					minWidthValue.Value = ScaleValueStringBy(minWidthValue.Value, multiplier);

					foreach (XmlNode border in clientAreaBorder) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode border in closeButtonBorder) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode drawable in closeButtonDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
					if (dialogDrawable != null) {foreach (XmlNode drawable in dialogDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}}
					foreach (XmlNode border in titleTextBorder) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "FillBarController")
				{
					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}
				}
				else if (nodeClass.Value == "ItemGrid")
				{
					XmlNode cellArea = null;
					XmlNode cellPadding = null;
					XmlNode gridPadding = null;
					XmlNode gridClipPadding = null;
					XmlNode hoverEffectsClip = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "CellArea") {cellArea = property;}
						else if (propertyName.Value == "CellPadding") {cellPadding = property;}
						else if (propertyName.Value == "GridPadding") {gridPadding = property;}
						else if (propertyName.Value == "GridClipPadding") {gridClipPadding = property;}
						else if (propertyName.Value == "HoverEffectsClip") {hoverEffectsClip = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode cellAreaValue = cellArea.Attributes.GetNamedItem("value");
					cellAreaValue.Value = ScalePointStringBy(cellAreaValue.Value, multiplier);
					XmlNode cellPaddingValue = cellPadding.Attributes.GetNamedItem("value");
					cellPaddingValue.Value = ScaleAreaStringBy(cellPaddingValue.Value, multiplier);
					XmlNode gridPaddingValue = gridPadding.Attributes.GetNamedItem("value");
					gridPaddingValue.Value = ScaleAreaStringBy(gridPaddingValue.Value, multiplier);

					if (gridClipPadding != null)
					{
						XmlNode gridClipPaddingValue = gridClipPadding.Attributes.GetNamedItem("value");
						gridClipPaddingValue.Value = ScaleAreaStringBy(gridClipPaddingValue.Value, multiplier);
					}

					if (hoverEffectsClip != null)
					{
						XmlNode hoverEffectsClipValue = hoverEffectsClip.Attributes.GetNamedItem("value");
						hoverEffectsClipValue.Value = ScaleAreaStringBy(hoverEffectsClipValue.Value, multiplier);
					}
				}
				else if (
					   nodeClass.Value == "ColumnControl"
					|| nodeClass.Value == "TabControl"
					|| nodeClass.Value == "SkewerTabControl"
					|| nodeClass.Value == "ColorPicker"
					|| nodeClass.Value == "ObjectPicker"
					|| nodeClass.Value == "BubbleMeter"
					|| nodeClass.Value == "CompetitionPanelColumnControl"
					|| nodeClass.Value == "BotCompetitionPanelColumnControl"
					|| nodeClass.Value == "FutreThemeTabControl"
					|| nodeClass.Value == "FutureThemeTabControl"
					|| nodeClass.Value == "BrownFilterTabControl"
					|| nodeClass.Value == "BrowserWin"
					|| nodeClass.Value == "FilterTabControl"
					|| nodeClass.Value == "StoreTabControl"
					|| nodeClass.Value == "VerticalTabControl"
				)
				{
					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
					}
				}
				else if (nodeClass.Value == "ScrollWindow" || nodeClass.Value == "TabContainer")
				{
					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
					}
				}
				else if (
					   nodeClass.Value == "CustomContentIcon"
					|| nodeClass.Value == "ExpandableCatalogGrid"
					|| nodeClass.Value == "DifficultyMeter"
					|| nodeClass.Value == "WindowPointer"
					|| nodeClass.Value == "RelationshipBar"
				)
				{
					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}
				}
				else if (nodeClass.Value == "AutosizeControl")
				{
					XmlNode horizontalMaxWidth = null;
					XmlNode verticalMaxHeight = null;
					XmlNode subtractHeightBuffer = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Horizontal-MaxWidth") {horizontalMaxWidth = property;}
						else if (propertyName.Value == "Vertical-MaxHeight") {verticalMaxHeight = property;}
						else if (propertyName.Value == "Subtract Height Buffer") {subtractHeightBuffer = property;}
					}

					XmlNode subtractHeightBufferValue = subtractHeightBuffer.Attributes.GetNamedItem("value");
					subtractHeightBufferValue.Value = ScaleValueStringBy(subtractHeightBufferValue.Value, multiplier);

					XmlNode horizontalMaxWidthValue = horizontalMaxWidth.Attributes.GetNamedItem("value");
					float horizontalMaxWidthScalar = ValueFromString(horizontalMaxWidthValue.Value);

					if (horizontalMaxWidthScalar != -1)
					{
						horizontalMaxWidthValue.Value = ValueToString(horizontalMaxWidthScalar * multiplier);
					}

					XmlNode verticalMaxHeightValue = verticalMaxHeight.Attributes.GetNamedItem("value");
					float verticalMaxHeightScalar = ValueFromString(verticalMaxHeightValue.Value);

					if (verticalMaxHeightScalar != -1)
					{
						verticalMaxHeightValue.Value = ValueToString(verticalMaxHeightScalar * multiplier);
					}
				}
				else if (nodeClass.Value == "FrameDrawable")
				{
					XmlNode borderWidth = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						if (propertyName.Value == "BorderWidth") {borderWidth = property;}
					}

					foreach (XmlNode border in borderWidth) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "Slider")
				{
					XmlNode sliderDrawable = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "SliderDrawable") {sliderDrawable = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					HandleLayoutWinProcs(controlID, ref winProcs, state.result.sliderLayoutWinProcsByControlID, NodeScalingState.State.WinProcsForSlider, multiplier, ref state);

					foreach (XmlNode drawable in sliderDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
				}
				else if (nodeClass.Value == "SceneMgrWindow")
				{
					XmlNode fillDrawable = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "FillDrawable") {fillDrawable = property;}
					}

					if (fillDrawable != null) {foreach (XmlNode drawable in fillDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}}
				}
				else if (
					   nodeClass.Value == "VerticalScrollbar"
					|| nodeClass.Value == "HorizontalScrollbar"
					|| nodeClass.Value == "Scrollbar"
				)
				{
					XmlNode scrollbarDrawable = null;
					XmlNode minThumbSize = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "MinThumbSize") {minThumbSize = property;}
						else if (propertyName.Value == "ScrollbarDrawable") {scrollbarDrawable = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode minThumbSizeValue = minThumbSize.Attributes.GetNamedItem("value");

					stringBuilder.Clear();
					stringBuilder.AppendFormat(Parsing.integerFormat, intDecimalFormatString, (int) Math.Floor((float) int.Parse(minThumbSizeValue.Value, Parsing.integerFormat) * multiplier));

					minThumbSizeValue.Value = stringBuilder.ToString();

					HandleLayoutWinProcs(controlID, ref winProcs, state.result.scrollbarLayoutWinProcsByControlID, NodeScalingState.State.WinProcsForScrollbar, multiplier, ref state);

					foreach (XmlNode drawable in scrollbarDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
				}
				else if (nodeClass.Value == "TableContainer" || nodeClass.Value == "AnimationTableContainer")
				{
					XmlNode rowHeight = null;
					XmlNode scrollBarPadding = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "Children") {children = property;}
						else if (propertyName.Value == "RowHeight") {rowHeight = property;}
						else if (propertyName.Value == "ScrollBarPadding") {scrollBarPadding = property;}
					}

					XmlNode rowHeightValue = rowHeight.Attributes.GetNamedItem("value");

					stringBuilder.Clear();
					stringBuilder.AppendFormat(Parsing.integerFormat, intDecimalFormatString, (uint) Math.Floor((float) uint.Parse(rowHeightValue.Value, Parsing.integerFormat) * multiplier));

					rowHeightValue.Value = stringBuilder.ToString();

					XmlNode scrollBarPaddingValue = scrollBarPadding.Attributes.GetNamedItem("value");
					scrollBarPaddingValue.Value = ScaleValueStringBy(scrollBarPaddingValue.Value, multiplier);
				}
				else if (nodeClass.Value == "Grid")
				{
					XmlNode cellGutters = null;
					XmlNode clipGutters = null;
					XmlNode defaultColumnWidth = null;
					XmlNode defaultRowHeight = null;
					XmlNode gutters = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "CellGutters") {cellGutters = property;}
						else if (propertyName.Value == "ClipGutters") {clipGutters = property;}
						else if (propertyName.Value == "DefaultColumnWidth") {defaultColumnWidth = property;}
						else if (propertyName.Value == "DefaultRowHeight") {defaultRowHeight = property;}
						else if (propertyName.Value == "Gutters") {gutters = property;}
						else if (propertyName.Value == "WinProcs") {winProcs = property;}
					}

					XmlNode defaultColumnWidthValue = defaultColumnWidth.Attributes.GetNamedItem("value");
					defaultColumnWidthValue.Value = ScaleValueStringBy(defaultColumnWidthValue.Value, multiplier);
					XmlNode defaultRowHeightValue = defaultRowHeight.Attributes.GetNamedItem("value");
					defaultRowHeightValue.Value = ScaleValueStringBy(defaultRowHeightValue.Value, multiplier);

					foreach (XmlNode border in cellGutters) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode border in clipGutters) {ScaleNodeBy(border, multiplier, ref state);}
					foreach (XmlNode border in gutters) {ScaleNodeBy(border, multiplier, ref state);}
				}
				else if (nodeClass.Value == "Spinner")
				{
					XmlNode spinnerDrawable = null;

					foreach (XmlNode property in xml)
					{
						if (property.NodeType != XmlNodeType.Element) {continue;}

						XmlNode propertyName = property.Attributes.GetNamedItem("name");

						     if (propertyName.Value == "Area") {area = property;}
						else if (propertyName.Value == "ControlID") {controlID = property;}
						else if (propertyName.Value == "SpinnerDrawable") {spinnerDrawable = property;}
					}

					foreach (XmlNode drawable in spinnerDrawable) {ScaleNodeBy(drawable, multiplier, ref state);}
				}
				else
				{
					foreach (var scaler in state.extraScalers)
					{
						bool nodeWasRecognised = scaler(xml, multiplier, ref state);

						if (nodeWasRecognised) {break;}
					}

					return;
				}

				if (area != null)
				{
					XmlNode areaValue = area.Attributes.GetNamedItem("value");
					areaValue.Value = ScaleAreaStringBy(areaValue.Value, multiplier);
				}

				if (winProcs != null)
				{
					foreach (XmlNode winProc in winProcs) {ScaleNodeBy(winProc, multiplier, ref state);}
				}

				if (controlID != null)
				{
					XmlNode controlIDValue = controlID.Attributes.GetNamedItem("value");
					var controlIDInt = Convert.ToUInt32(controlIDValue.Value, 16);

					state.controlIDChain.Add(controlIDInt);
				}

				if (children != null)
				{
					foreach (XmlNode child in children) {ScaleNodeBy(child, multiplier, ref state);}
				}

				if (controlID != null)
				{
					state.controlIDChain.RemoveAt(state.controlIDChain.Count - 1);
				}
			}
			else if (xml.Name == "graph")
			{
				foreach (XmlNode child in xml) {ScaleNodeBy(child, multiplier, ref state);}
			}
		}

		private static void HandleLayoutWinProcs (
			XmlNode controlID,
			ref XmlNode winProcs,
			Dictionary<uint, List<ValueTuple<LayoutWinProc, ControlIDChain>>> layoutWinProcsByControlID,
			NodeScalingState.State stateMask,
			float multiplier,
			ref NodeScalingState state
		)
		{
			if (winProcs != null)
			{
				XmlNode controlIDValue = controlID.Attributes.GetNamedItem("value");
				var controlIDInt = Convert.ToUInt32(controlIDValue.Value, 16);

				state.controlIDChain.Add(controlIDInt);
				state.state |= stateMask;

				if (!layoutWinProcsByControlID.ContainsKey(controlIDInt))
				{
					layoutWinProcsByControlID[controlIDInt] = new List<ValueTuple<LayoutWinProc, ControlIDChain>>();
				}

				foreach (XmlNode winProc in winProcs) {ScaleNodeBy(winProc, multiplier, ref state);}

				state.controlIDChain.RemoveAt(state.controlIDChain.Count - 1);
				state.state &= ~stateMask;

				winProcs = null;
			}
		}
	}

	public static class StyleSheetScaler
	{
		public const string floatFormatString = "{0:F9}";

		static readonly Regex fontSizeValueRegEx = new Regex(@"^((?:[0-9]*\.)?[0-9]+)([a-zA-Z]+)?(.*)", RegexOptions.Compiled);
		static readonly Regex lineSpacingValueRegEx = new Regex(@"^((?:[0-9]*\.)?[0-9]+)(.*)", RegexOptions.Compiled);

		[ThreadStatic] static StringBuilder stringBuilder;

		public static void InitialiseForCurrentThread ()
		{
			stringBuilder = new StringBuilder(30);
		}

		public static string ScaleStyleSheetBy (string css, float multiplier)
		{
			/* The style-sheets used for the text-styles in the Sims 3 are written in some bizarre CSS-but-not-quite language.
			   We don't really care about parsing it. So long as we handle comments and string-literals, we can just
			   passthrough anything we don't understand. Which is good, because we don't understand most of it. */

			if (stringBuilder == null)
			{
				InitialiseForCurrentThread();
			}

			var rewritten = new StringBuilder(css.Length + 1024);
			int index = 0;
			int length = css.Length;

			int blockDepth = 0;
			int propertyStartOffset = 0;
			int propertyEndOffset = 0;
			int valueStartOffset = 0;
			int valueEndOffset = 0;
			int declarationStage = 0;
			int rewrittenIndexDelta = 0;

			char c;

			for (;;)
			{
				if (declarationStage == 4)
				{
					declarationStage = 0;

					string rewrittenValue = null;
					int valueLength = 0;

					if (string.Compare(css, propertyStartOffset, "font-size", 0, propertyEndOffset - propertyStartOffset) == 0)
					{
						valueLength = valueEndOffset - valueStartOffset;
						var matches = fontSizeValueRegEx.Match(css, valueStartOffset, valueLength);

						if (matches.Success)
						{
							stringBuilder.Clear();
							stringBuilder.AppendFormat(Parsing.floatFormat, floatFormatString, float.Parse(matches.Groups[1].Value, Parsing.floatFormat) * multiplier);
							stringBuilder.Append(matches.Groups[2].Value);
							stringBuilder.Append(matches.Groups[3].Value);
							rewrittenValue = stringBuilder.ToString();
						}
					}
					else if (string.Compare(css, propertyStartOffset, "line-spacing", 0, propertyEndOffset - propertyStartOffset) == 0)
					{
						valueLength = valueEndOffset - valueStartOffset;
						var matches = fontSizeValueRegEx.Match(css, valueStartOffset, valueLength);

						if (matches.Success)
						{
							stringBuilder.Clear();
							stringBuilder.AppendFormat(Parsing.floatFormat, floatFormatString, float.Parse(matches.Groups[1].Value, Parsing.floatFormat) * multiplier);
							stringBuilder.Append(matches.Groups[2].Value);
							rewrittenValue = stringBuilder.ToString();
						}
					}

					if (rewrittenValue != null)
					{
						int adjustedValueStartOffset = valueStartOffset + rewrittenIndexDelta;

						rewritten.Remove(adjustedValueStartOffset, valueLength);
						rewritten.Insert(adjustedValueStartOffset, rewrittenValue);

						rewrittenIndexDelta += rewrittenValue.Length - valueLength;
					}
				}

				if (index >= length)
				{
					break;
				}

				c = css[index];

				if (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f')
				{
					rewritten.Append(c);
					++index;

					continue;
				}

				if (c == '/')
				{
					rewritten.Append(c);
					++index;

					if (index >= length) {goto endOfCodeUnits;}

					c = css[index];

					if (c == '/')
					{
						rewritten.Append(c);
						++index;

						do
						{
							if (index >= length) {goto endOfCodeUnits;}

							c = css[index];
							rewritten.Append(c);
							++index;
						}
						while (c != '\n' && c != '\r' && c != '\f');
					}
					else if (c == '*')
					{
						for (;;)
						{
							rewritten.Append(c);
							++index;

							if (index >= length) {goto endOfCodeUnits;}

							c = css[index];

							if (c == '*')
							{
								rewritten.Append(c);
								++index;

								if (index >= length) {goto endOfCodeUnits;}

								c = css[index];

								if (c == '/')
								{
									rewritten.Append(c);
									++index;

									break;
								}
							}
						}
					}

					continue;
				}

				if (c == '"')
				{
					for (;;)
					{
						rewritten.Append(c);
						++index;

						if (index >= length) {goto endOfCodeUnits;}

						c = css[index];

						if (c == '\\')
						{
							rewritten.Append(c);
							++index;

							if (index >= length) {goto endOfCodeUnits;}

							c = css[index];

							continue;
						}

						if (c == '"')
						{
							rewritten.Append(c);
							++index;

							break;
						}
					}

					continue;
				}

				if (c == '\\')
				{
					for (;;)
					{
						rewritten.Append(c);
						++index;

						if (index >= length) {goto endOfCodeUnits;}

						c = css[index];

						if (c == '\\')
						{
							rewritten.Append(c);
							++index;

							if (index >= length) {goto endOfCodeUnits;}

							c = css[index];

							continue;
						}

						if (c == '\\')
						{
							rewritten.Append(c);
							++index;

							break;
						}
					}

					continue;
				}

				if (c == '{')
				{
					++blockDepth;

					rewritten.Append(c);
					++index;

					continue;
				}

				if (c == '}')
				{
					if (blockDepth > 0)
					{
						--blockDepth;
					}

					declarationStage = declarationStage == 3 ? 4 : 0;

					rewritten.Append(c);
					++index;

					continue;
				}

				if (blockDepth == 0)
				{
					rewritten.Append(c);
					++index;

					continue;
				}

				if (c == ';')
				{
					declarationStage = declarationStage == 3 ? 4 : 0;

					rewritten.Append(c);
					++index;

					continue;
				}

				if (c == ':')
				{
					declarationStage = 2;

					rewritten.Append(c);
					++index;

					continue;
				}

				if (declarationStage <= 1)
				{
					if (declarationStage == 0)
					{
						declarationStage = 1;
						propertyStartOffset = index;
					}

					rewritten.Append(c);
					++index;

					propertyEndOffset = index;

					continue;
				}

				if (declarationStage >= 2)
				{
					if (declarationStage == 2)
					{
						declarationStage = 3;
						valueStartOffset = index;
					}

					rewritten.Append(c);
					++index;

					valueEndOffset = index;

					continue;
				}

				rewritten.Append(c);
				++index;
			}
		endOfCodeUnits: {}

			return rewritten.ToString();
		}
	}

	public static class ResourceManipulator
	{
		static Dictionary<uint, uint> testDictionary;

		static ResourceManipulator ()
		{
			testDictionary = new Dictionary<uint, uint>();
		}

		public struct FoundResources <IResourceKey, ConstructableResourceKey>
		where ConstructableResourceKey : IResourceKey
		{
			public Dictionary<IResourceKey, string> byKey;
			public Dictionary<uint, Dictionary<ConstructableResourceKey, string>> byResourceType;
			public Dictionary<object, Dictionary<ConstructableResourceKey, string>> byCondition;
		}

		public static FoundResources<IResourceKey, ConstructableResourceKey> FindResourcesAcrossPackages <IResourceKey, ConstructableResourceKey, IPackage> (
			Dictionary<ulong, IEnumerable<Object>> prioritisedFiles,
			DirectoryInfo baseDirectory,
			HashSet<IResourceKey> byKey,
			uint[] byResourceType,
			ValueTuple<object, Func<IPackage, IResourceKey, bool>>[] byCondition,
			Func<int, string, bool, IPackage> openPackage,
			Action<int, IPackage> closePackage,
			Func<IPackage, IEnumerable<IResourceKey>> getResourceListOfPackage,
			Func<IResourceKey, ulong> getInstanceOfResourceKey,
			Func<IResourceKey, uint> getResourceTypeOfResourceKey,
			Func<IResourceKey, uint> getResourceGroupOfResourceKey,
			Func<IResourceKey, ConstructableResourceKey> constructResourceKey,
			Action<Exception> logWarning
		)
		where ConstructableResourceKey : IResourceKey
		{
			var foundByKey = new Dictionary<IResourceKey, string>(byKey.Count);
			var foundByResourceType = new Dictionary<uint, Dictionary<ConstructableResourceKey, string>>(byResourceType.Length);
			var foundByCondition = new Dictionary<object, Dictionary<ConstructableResourceKey, string>>();

			foreach (uint resourceType in byResourceType)
			{
				foundByResourceType[resourceType] = new Dictionary<ConstructableResourceKey, string>();
			}

			var priorities = prioritisedFiles.Keys.ToArray();
			Array.Sort(priorities, (a, b) => b.CompareTo(a));

			foreach (var priority in priorities)
			{
				var files = prioritisedFiles[priority];

				foreach (var file in files)
				{
					string filePath = file is string ? Path.Combine(baseDirectory.FullName, file as string) : (file as FileInfo).FullName;

					try
					{
						IPackage package = openPackage(1, filePath, false);

						try
						{
							foreach (var entry in getResourceListOfPackage(package))
							{
								foreach (var key in byKey)
								{
									if (
										   getInstanceOfResourceKey(key) == getInstanceOfResourceKey(entry)
										&& getResourceTypeOfResourceKey(key) == getResourceTypeOfResourceKey(entry)
										&& getResourceGroupOfResourceKey(key) == getResourceGroupOfResourceKey(entry)
									)
									{
										foundByKey[key] = filePath;

										byKey.Remove(key);

										goto examinedEntry;
									}
								}

								foreach (var resourceType in byResourceType)
								{
									if (resourceType == getResourceTypeOfResourceKey(entry))
									{
										Dictionary<ConstructableResourceKey, string> found = null;

										foundByResourceType.TryGetValue(resourceType, out found);

										ConstructableResourceKey key = constructResourceKey(entry);

										if (!found.ContainsKey(key))
										{
											found.Add(key, filePath);
										}

										goto examinedEntry;
									}
								}

								foreach (var condition in byCondition)
								{
									if (condition.Item2(package, entry))
									{
										Dictionary<ConstructableResourceKey, string> found = null;

										if (!foundByCondition.TryGetValue(condition.Item1, out found))
										{
											found = new Dictionary<ConstructableResourceKey, string>();
											foundByCondition[condition.Item1] = found;
										}

										ConstructableResourceKey key = constructResourceKey(entry);

										if (!found.ContainsKey(key))
										{
											found.Add(key, filePath);
										}

										goto examinedEntry;
									}
								}
							examinedEntry: {}
							}
						}
						finally
						{
							closePackage(1, package);
						}
					}
					catch (Exception error)
					{
						logWarning(error);
					}

					if (foundByResourceType.Count <= 0 && byCondition.Length <= 0 && byKey.Count <= 0)
					{
						goto finishedSearchingPackages;
					}
				}
			}
		finishedSearchingPackages: {}

			return new FoundResources<IResourceKey, ConstructableResourceKey>{
				byKey = foundByKey,
				byResourceType = foundByResourceType,
				byCondition = foundByCondition
			};
		}
	}

	public static class AssemblyScaling
	{
		public class PrimitiveAssemblyResolver : IAssemblyResolver
		{
			public Dictionary<ValueTuple<String, Version>, AssemblyDefinition> assemblies;

			public PrimitiveAssemblyResolver ()
			{
				this.assemblies = new Dictionary<ValueTuple<String, Version>, AssemblyDefinition>();
			}

			public AssemblyDefinition Resolve (ValueTuple<String, Version> key)
			{
				AssemblyDefinition assembly;
				this.assemblies.TryGetValue(key, out assembly);

				return assembly;
			}

			public AssemblyDefinition Resolve (AssemblyNameReference name)
			{
				return this.Resolve(KeyFor(name));
			}

			public AssemblyDefinition Resolve (AssemblyNameReference name, ReaderParameters parameters)
			{
				return this.Resolve(name);
			}

			public void Dispose ()
			{}

			public static ValueTuple<String, Version> KeyFor (AssemblyNameReference name)
			{
				return new ValueTuple<String, Version>(name.Name, name.Version);
			}

			public static ValueTuple<String, Version> KeyFor (AssemblyDefinition assembly)
			{
				return KeyFor(assembly.Name);
			}

			public ValueTuple<String, Version> Add (AssemblyDefinition assembly)
			{
				var key = KeyFor(assembly);
				this.assemblies[key] = assembly;
				return key;
			}

			public ValueTuple<String, Version> Add (Stream assembly)
			{
				return this.Add(AssemblyDefinition.ReadAssembly(assembly));
			}
		}

		public static class AssemblyInspection
		{
			public static IEnumerable<TypeDefinition> DescendantTypesOf (TypeDefinition type)
			{
				return type.NestedTypes.SelectMany(t => DescendantTypesOf(t).Prepend(t));
			}

			public static IEnumerable<TypeDefinition> DescendantTypesOf (ModuleDefinition module)
			{
				return module.Types.SelectMany(t => DescendantTypesOf(t).Prepend(t));
			}

			public static IEnumerable<TypeDefinition> DescendantTypesOf (AssemblyDefinition assembly)
			{
				return assembly.Modules.SelectMany(DescendantTypesOf);
			}

			public static IEnumerable<TypeDefinition> DescendantTypesOf (IEnumerable<AssemblyDefinition> assemblies)
			{
				return assemblies.SelectMany(DescendantTypesOf);
			}

			public static IEnumerable<MethodDefinition> MethodDefinitionsOf (TypeDefinition type)
			{
				return type.Methods.Concat(type.Properties.SelectMany(MethodDefinitionsOf));
			}

			public static IEnumerable<MethodDefinition> MethodDefinitionsOf (PropertyDefinition property)
			{
				var methods = Enumerable.Empty<MethodDefinition>();
				if (property.GetMethod != null) methods.Append(property.GetMethod);
				if (property.SetMethod != null) methods.Append(property.SetMethod);

				return methods;
			}

			public static IEnumerable<MethodDefinition> MethodDefinitionsOf (ModuleDefinition module)
			{
				return DescendantTypesOf(module).SelectMany(MethodDefinitionsOf);
			}

			public static IEnumerable<MethodDefinition> MethodDefinitionsOf (AssemblyDefinition assembly)
			{
				return assembly.Modules.SelectMany(MethodDefinitionsOf);
			}

			public static IEnumerable<MethodDefinition> MethodDefinitionsOf (IEnumerable<AssemblyDefinition> assemblies)
			{
				return assemblies.SelectMany(MethodDefinitionsOf);
			}
		}

		public static class MethodInspection
		{
			public static IEnumerable<Instruction> CallsIn (MethodBody method)
			{
				return method.Instructions.Where(i => (i.OpCode.Code == Code.Call) | (i.OpCode.Code == Code.Callvirt));
			}
		}

		public static class OpCodeInspection
		{
			internal static readonly sbyte[] stackDepthChangeEffectedByOpCodes = InitialiseStackDepthChangeEffectedByOpCodes();

			private static sbyte[] InitialiseStackDepthChangeEffectedByOpCodes ()
			{
				var stackBehaviours = Enum.GetValues(typeof(StackBehaviour));
				var stackDepthChanges = new sbyte[stackBehaviours.Cast<int>().Max() + 1];

				stackDepthChanges[(int) StackBehaviour.Pop0] = 0;
				stackDepthChanges[(int) StackBehaviour.Pop1] = -1;
				stackDepthChanges[(int) StackBehaviour.Pop1_pop1] = -2;
				stackDepthChanges[(int) StackBehaviour.Popi] = -1;
				stackDepthChanges[(int) StackBehaviour.Popi_pop1] = -2;
				stackDepthChanges[(int) StackBehaviour.Popi_popi] = -2;
				stackDepthChanges[(int) StackBehaviour.Popi_popi8] = -2;
				stackDepthChanges[(int) StackBehaviour.Popi_popi_popi] = -3;
				stackDepthChanges[(int) StackBehaviour.Popi_popr4] = -2;
				stackDepthChanges[(int) StackBehaviour.Popi_popr8] = -2;
				stackDepthChanges[(int) StackBehaviour.Popref] = -1;
				stackDepthChanges[(int) StackBehaviour.Popref_pop1] = -2;
				stackDepthChanges[(int) StackBehaviour.Popref_popi] = -2;
				stackDepthChanges[(int) StackBehaviour.Popref_popi_popi] = -3;
				stackDepthChanges[(int) StackBehaviour.Popref_popi_popi8] = -3;
				stackDepthChanges[(int) StackBehaviour.Popref_popi_popr4] = -3;
				stackDepthChanges[(int) StackBehaviour.Popref_popi_popr8] = -3;
				stackDepthChanges[(int) StackBehaviour.Popref_popi_popref] = -3;
				stackDepthChanges[(int) StackBehaviour.PopAll] = -128;
				stackDepthChanges[(int) StackBehaviour.Push0] = 0;
				stackDepthChanges[(int) StackBehaviour.Push1] = +1;
				stackDepthChanges[(int) StackBehaviour.Push1_push1] = +2;
				stackDepthChanges[(int) StackBehaviour.Pushi] = +1;
				stackDepthChanges[(int) StackBehaviour.Pushi8] = +1;
				stackDepthChanges[(int) StackBehaviour.Pushr4] = +1;
				stackDepthChanges[(int) StackBehaviour.Pushr8] = +1;
				stackDepthChanges[(int) StackBehaviour.Pushref] = +1;
				stackDepthChanges[(int) StackBehaviour.Varpop] = -128;
				stackDepthChanges[(int) StackBehaviour.Varpush] = -128;

				return stackDepthChanges;
			}

			public static bool StaticallyKnownStackDepthChangeEffectedBy (StackBehaviour behaviour, out int effect)
			{
				effect = stackDepthChangeEffectedByOpCodes[(int) behaviour];

				return effect != -128;
			}

			public static bool StaticallyKnownStackDepthChangeEffectedBy (StackBehaviour push, StackBehaviour pop, out int effect)
			{
				effect = stackDepthChangeEffectedByOpCodes[(int) push] + stackDepthChangeEffectedByOpCodes[(int) pop];

				return effect > -126;
			}

			public static bool StaticallyKnownStackDepthChangeEffectedBy (OpCode opcode, out int effect)
			{
				return StaticallyKnownStackDepthChangeEffectedBy(opcode.StackBehaviourPush, opcode.StackBehaviourPop, out effect);
			}

			public static bool StaticallyKnownStackDepthChangeEffectedBy (Instruction instruction, out int effect)
			{
				if (instruction.OpCode.FlowControl == FlowControl.Call)
				{
					if (instruction.OpCode.Code == Code.Calli)
					{
						effect = -128;

						return false;
					}

					var method = instruction.Operand as MethodReference;

					if (!StaticallyKnownStackDepthChangeEffectedBy(instruction.OpCode.StackBehaviourPush, out effect))
					{
						effect = method.ReturnType != method.Module.TypeSystem.Void ? 1 : 0;
					}

					effect -= method.HasThis ? 1 : 0;
					effect -= method.Parameters.Count;

					return true;
				}
				else
				{
					return StaticallyKnownStackDepthChangeEffectedBy(instruction.OpCode, out effect);
				}
			}
		}

		public static class InstructionPatching
		{
			public static void ReplaceBranchTargetsIn (IEnumerable<Instruction> instructions, Instruction from, Instruction to)
			{
				foreach (var instruction in instructions)
				{
					var operandType = instruction.OpCode.OperandType;

					if ((operandType == OperandType.InlineBrTarget) | (operandType == OperandType.ShortInlineBrTarget))
					{
						if (instruction.Operand as Instruction == from)
						{
							instruction.Operand = to;
						}
					}
				}
			}
		}

		public class CallersOfGraph
		{
			public Dictionary<MethodDefinition, HashSet<MethodReference>> graph;

			public CallersOfGraph ()
			{
				this.graph = new Dictionary<MethodDefinition, HashSet<MethodReference>>();
			}

			public HashSet<MethodReference> CallersOf (MethodDefinition method)
			{
				HashSet<MethodReference> callers;
				this.graph.TryGetValue(method, out callers);

				return callers;
			}

			public HashSet<MethodReference> CallersOf (MethodReference method)
			{
				return this.CallersOf(method.Resolve());
			}

			public static CallersOfGraph For (IEnumerable<MethodDefinition> methods)
			{
				var callersOf = new CallersOfGraph();

				foreach (var caller in methods)
				{
					if (!caller.HasBody)
					{
						continue;
					}

					foreach (var call in MethodInspection.CallsIn(caller.Body))
					{
						var callee = ((MethodReference) call.Operand).Resolve();

						if (callee == null)
						{
							continue;
						}

						HashSet<MethodReference> knownCallers = null;

						if (!callersOf.graph.TryGetValue(callee, out knownCallers))
						{
							knownCallers = new HashSet<MethodReference>();
							callersOf.graph[callee] = knownCallers;
						}

						knownCallers.Add(caller);
					}
				}

				return callersOf;
			}
		}

		public static uint ReinterpretAsUnsigned (int value)
		{
			return unchecked((uint) value);
		}

		public static ulong ReinterpretAsUnsigned (long value)
		{
			return unchecked((ulong) value);
		}

		public static int ReinterpretAsSigned (uint value)
		{
			return unchecked((int) value);
		}

		public static long ReinterpretAsSigned (ulong value)
		{
			return unchecked((long) value);
		}
	}
}

