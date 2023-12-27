
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>

$ID = 'VanillaCoreCompatibilityPatch'
$Version = '1.0.1'
$PatchsetDefinitionSchemaVersion = 1

${If it's Christmas!} = $($Now = [DateTime]::Now; if ($Now.Month -eq 12 -and $Now.Day -eq 25) {'<hr>Merry Christmas! :)'} else {''})

[PSCustomObject] @{
	FriendlyName = 'Vanilla Core DLL Compatibility Patches'
	Description = "These patches make the game's core DLLs compatible with the UI scaling added by the Tiny UI Fix.$(${If it's Christmas!})"

	DuringUIScaling = @{
		PatchAssemblies = `
		{
			Param ($Self, $State)

			$UI = $State.Assemblies.Resolver.Resolve($State.Assemblies.AssemblyKeysByResourceKey[$TinyUIFixPSForTS3ResourceKeys.UIDLL])

			$ConvenientPatches = @{
				$TinyUIFixPSForTS3ResourceKeys.UIDLL = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'Sims3.UI'
					Patches = (
						('System.Void Sims3.UI.CAS.CASBeard::PopulateBeardPresets(System.Boolean)', @{Floats = 165, 182, 447}),
						('System.Void Sims3.UI.CAS.CASBodyHair::PopulateColorPresets(System.Boolean)', @{Floats = 17, 628}),
						('System.Void Sims3.UI.CAS.CASFacialBlendPanel::SetupTab(Sims3.UI.TabControl)', @{Floats = 10}),
						('System.Void Sims3.UI.CAS.CASFacialDetails::SetShortPanelHeight(System.Boolean)', @{Floats = 448, 545}),
						('System.Void Sims3.UI.CAS.CAP.CAPCoat::PopulateColors(System.Boolean)', @{Floats = 21}),
						('System.Void Sims3.UI.CAS.CAP.CAPFBDBasic::SetShortPanelHeight(System.Boolean)', @{Floats = 448, 545}),
						('System.Void Sims3.UI.CAS.CAP.CAPFBDBasic::SetLongPanelHeight(System.Boolean,System.Single)', @{Floats = 595, 616}),
						('System.Void Sims3.UI.CAS.CASEyebrows::PopulateColorPresets(System.Boolean)', @{Floats = 17, 628}),
						('System.Void Sims3.UI.CAS.CASEyes::PopulateEyeColorGrid()', @{Floats = 500, 521}),
						('System.Void Sims3.UI.CAS.CASMakeup::PopulatePresetsGrid(Sims3.SimIFace.CAS.BodyTypes,Sims3.SimIFace.CAS.CASPart,System.Boolean)', @{Floats = 40, 500, 521}),
						('System.Void Sims3.UI.CAS.CASMakeup::SetCategory(Sims3.SimIFace.CAS.BodyTypes)', @{Floats = 570}),
						('System.Void Sims3.UI.CAS.CASMirror::SetLongPanelHeight(System.Boolean)', @{Floats = 595, 616}),
						('System.Void Sims3.UI.CAS.CASPhysical::SetLongPanelHeight(System.Boolean)', @{Floats = 595, 616}),
						('System.Void Sims3.UI.CAS.CAP.CAPColoringTMH::PopulateColors(System.Boolean)', @{Floats = 21}),
						('System.Single Sims3.UI.CAS.CASClothing::SetHeight(System.Single)', @{StaticFields = 'kMinHeight'}),
						('System.Void Sims3.UI.CAS.CASHair::PopulateHairPresetsInternal()', @{Floats = 161, 182, 621, 642}),
						('System.Void Sims3.UI.CAS.CASHair::SetHairTypeCategory(Sims3.UI.CAS.CASHair/HairType)', @{Floats = 395, 421}),
						('System.Single Sims3.UI.InGameBrowser::SetupBreadCrumbButton(System.Int32,System.Boolean,System.String,System.Single,System.Boolean)', @{Floats = @{_ = 16; Truncated = $True}; Integers = 16, 782}),
						('System.Single Sims3.UI.MapTagGameEntryTooltip::ResizeTextControl(Sims3.UI.Text)', @{Floats = 14, 280}),
						('System.Void Sims3.UI.BBCatalogPreviewPanelController::AdjustForGridScrollbar()', @{StaticFields = 'kScrollbarOffset'}),
						('System.Void Sims3.UI.BBCatalogPreviewPanelController::AdjustForHiddenPanels(System.Boolean)', @{Floats = -76, -186}),
						('System.Void Sims3.UI.BBCatalogPreviewPanelController::ResizePreviewForItem()', @{Floats = -5, 10, 25, 93, 117, 193; StaticFields = 'kScrollbarOffset'}),
						('System.Void Sims3.UI.BBCatalogPreviewPanelController::SetWorkingObject()', @{Floats = -5, 5, 10, 25, 93, 117, 150, 193; StaticFields = 'kScrollbarOffset'}),
						('System.Void Sims3.UI.BBCatalogPreviewPanelController::SetWorkingProduct()', @{Floats = -5, 10, 25, 93, 150; StaticFields = 'kScrollbarOffset'}),
						('System.Boolean Sims3.UI.BlueprintController::AddGridItem(Sims3.UI.ItemGrid,System.Object,Sims3.SimIFace.ResourceKey,System.Object)', @{Floats = 54}),
						('System.Void Sims3.UI.BlueprintController::ResizeCatalogGrid(Sims3.UI.WindowBase,Sims3.UI.ItemGrid,System.Single,System.UInt32,System.Int32,System.Boolean)', @{InstanceFields = 'SCROLL_BAR_WIDTH'}),
						('System.Void Sims3.UI.BlueprintController::UpdateMiddlePuckSize(System.Boolean,System.Single)', @{InstanceFields = 'MIDDLE_PUCK_PADDING', 'PUCK_EXTRA'}),
						('System.Void Sims3.UI.BlueprintController::ResizeGrid(System.UInt32)', @{InstanceFields = 'GRID_ROOM_CONCISE_DIMENSIONS.y', 'MIDDLE_PUCK_MIN_SIZE', 'PUCK_EXTRA', 'SCROLL_BAR_WIDTH'}), # What's going on here?
						('Sims3.UI.Tooltip Sims3.UI.BlueprintController::Sims3.UI.ITooltippable.CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{StaticFields = 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.x', 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.y'}),
						('System.Void Sims3.UI.BuildController::ResizeCatalogGrid(Sims3.UI.ItemGrid,System.Int32,Sims3.UI.Window,Sims3.UI.Window,System.Boolean)', @{Floats = 4, 37, 100}),
						('System.UInt32 Sims3.UI.BuildController::GetNumColumnsToDisplay(Sims3.UI.ItemGrid)', @{Floats = 1, 16}),
						('System.Void Sims3.UI.BuildController::SetToolState(Sims3.UI.BuildController/ToolState)', @{Floats = 132, 168}),
						('System.Void Sims3.UI.BuildController/BuildItemTooltip::.ctor(Sims3.SimIFace.BuildBuy.BuildBuyProduct,System.Boolean,Sims3.SimIFace.ResourceKey,Sims3.SimIFace.CustomContent.ResourceKeyContentCategory)', @{Floats = 25}),
						('Sims3.UI.Tooltip Sims3.UI.BuildController::Sims3.UI.ITooltippable.CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{StaticFields = 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.x', 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.y'}),
						('System.Boolean Sims3.UI.BuyController::AddGridItem(Sims3.UI.ItemGrid,System.Object,Sims3.UI.WindowBase,System.Object)', @{Floats = 54}),
						('System.Void Sims3.UI.BuyController::ResizeCatalogGrid(Sims3.UI.WindowBase,Sims3.UI.ExpandableCatalogGrid,System.Single,System.UInt32,System.Int32,System.Boolean)', @{Floats = 30, 43; InstanceFields = 'SCROLL_BAR_WIDTH'}),
						('System.Void Sims3.UI.BuyController::UpdateMiddlePuckSize(System.Boolean,System.Single)', @{InstanceFields = 'MIDDLE_PUCK_MIN_SIZE', 'MIDDLE_PUCK_PADDING', 'PUCK_EXTRA'}),
						('System.Void Sims3.UI.BuyController::ResizeGrid(System.UInt32)', @{InstanceFields = 'GRID_CATEGORY_CONCISE_DIMENSIONS.y', 'GRID_ROOM_CONCISE_DIMENSIONS.y', 'GRID_INVENTORY_CONCISE_DIMENSIONS.y', 'MIDDLE_PUCK_MIN_SIZE', 'PUCK_EXTRA', 'PUCK_EXTRA_INVENTORY', 'SCROLL_BAR_WIDTH'}),
						('System.Void Sims3.UI.BuyController/BuyItemTooltip::.ctor(System.String,System.String,System.Single)', @{Floats = 15}),
						('Sims3.UI.Tooltip Sims3.UI.BuyController::Sims3.UI.ITooltippable.CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{StaticFields = 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.x', 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.y'}),
						('System.Void Sims3.UI.CAS.CAP.CAPUnicorn::PopulateBeardColors()', @{Floats = 21}),
						('System.Void Sims3.UI.CAS.CAP.CAPUnicorn::PopulateHornColors()', @{Floats = 21}),
						##('System.Void Sims3.UI.CAS.CAPSmallMultiColorPickerDialog::.ctor(Sims3.SimIFace.Color[],System.Int32,System.Boolean,System.String,Sims3.UI.CAS.CAPSmallMultiColorPickerDialog/PickerType,Sims3.SimIFace.CAS.CASPart[],Sims3.SimIFace.CAS.CASPart,Sims3.SimIFace.Vector2)', @{Floats = 18}), # 18 for RegisterWindowCursor.
						('System.Void Sims3.UI.CAS.CASBasics::SetupWindowHeight()', @{Floats = 588}),
						('System.Void Sims3.UI.CAS.CASBasics::SetupWindowHeightFromVisibleSliderCount()', @{Integers = 30, 50, 438}),
						('System.Void Sims3.UI.CAS.CASCharacter::SelectWish(Sims3.UI.Hud.IInitialMajorWish)', @{Floats = 10}),
						('System.Void Sims3.UI.CAS.CASFacialDetails::SetLongPanelHeight(System.Boolean,System.Single)', @{Floats = 595, 616}),
						#('System.Void Sims3.UI.CAS.CASHairAdvancedDialog::.ctor(Sims3.SimIFace.CAS.BodyTypes,System.Collections.Generic.List`1<Sims3.SimIFace.Color>,System.String,System.Boolean)', @{Floats = 18}), # 18 for RegisterWindowCursor.
						#('System.Void Sims3.UI.CAS.CASMultiColorPickerDialog::.ctor(Sims3.SimIFace.Color[],System.Int32,System.Boolean,System.String,Sims3.UI.CAS.CASMultiColorPickerDialog/PickerType,Sims3.SimIFace.CAS.CASPart[],Sims3.SimIFace.CAS.CASPart,Sims3.SimIFace.Vector2)', @{Floats = 18}), # 18 for RegisterWindowCursor.
						('System.Void Sims3.UI.CAS.CASPlasticSurgeryBody::SetupWindowHeightFromVisibleSliderCount()', @{Integers = 30, 50, 438}),
						('System.Void Sims3.UI.CAS.CASPuck::HideAdvancedCAPPuck()', @{Floats = 55}),
						('System.Void Sims3.UI.CAS.CASPuck::ShowAdvancedCAPPuck(Sims3.UI.CAS.CASState)', @{Floats = 55}),
						('System.Void Sims3.UI.CAS.CASPuck::UpdateSimButtons()', @{Floats = 55, 432}),
						('System.Void Sims3.UI.CAS.CASRequiredItemsDialog::SelectWish(Sims3.UI.Hud.IInitialMajorWish)', @{Floats = 10}),
						('System.Void Sims3.UI.ColorPicker::UpdateSelectorPositionPoint(Sims3.SimIFace.Vector2)', @{Floats = -2, 12, 76.5}), # Might be wrong.
						('System.Void Sims3.UI.ColorPicker::UpdateColorChange()', @{Floats = 12}), # Might be wrong.
						('System.Void Sims3.UI.ColorPicker::UpdateSelector()', @{Floats = 12}), # Might be wrong.
						('Sims3.SimIFace.Vector2 Sims3.UI.ColorPicker::PointFromHueSaturation(System.Single,System.Single)', @{Floats = 76.5}), # Might be wrong.
						('System.Void Sims3.UI.ColorPicker::HueSaturationFromPoint(Sims3.SimIFace.Vector2,System.Single&,System.Single&)', @{Floats = 76.5}), # Might be wrong.
						('System.Void Sims3.UI.ConnectedNewComment::Show()', @{StaticFields = 'kMaxSize'}),
						('System.Void Sims3.UI.ConnectedNewPost::Show()', @{StaticFields = 'kMaxSize'}),
						('System.Void Sims3.UI.ConnectedOfflineMsg::Show()', @{StaticFields = 'kMaxSize'}),
						('System.Void Sims3.UI.ConnectedPassportMsg::Show()', @{StaticFields = 'kMaxSize'}),
						('System.Void Sims3.UI.Controller.HUD.HUDClassSchedule::.ctor()', @{Floats = 50}),
						('System.Void Sims3.UI.CustomContentIcon::UpdateSize()', @{StaticFields = 'kCutoffHeight', 'kTinyCutoffHeight'}),
						('System.Void Sims3.UI.FriendProfileController::.ctor(System.Int64)', @{Floats = 25, 125}),
						('System.Void Sims3.UI.FriendProfileController::ShowIndividualPost(System.Object)', @{Floats = 111}),
						('System.Void Sims3.UI.GameEntry.MainMenu::PopulateWorldFileComboBox()', @{Floats = 15, 27, 205, 227}),
						('System.Void Sims3.UI.GameEntry.MainMenu::UpdateFsiWorldPurchaseVisibility()', @{Floats = 40}),
						('System.Void Sims3.UI.GenieWishSelectionDialog::.ctor(System.Collections.Generic.List`1<Sims3.UI.Hud.IGenieWish>)', @{Floats = 50}),
						('System.Void Sims3.UI.Hud.AdventureRewardsShopDialog::.ctor()', @{Floats = 50}),
						('System.Void Sims3.UI.Hud.CareerPanel::UpdateHolidays(System.UInt32,System.UInt32,Sims3.UI.WindowBase,System.UInt32,System.Single)', @{Floats = 22}),
						('System.Void Sims3.UI.Hud.CollectionJournalDialog::BuildStatsList()', @{StaticFields = 'kChallegeHeightBuffer'}),
						('System.Void Sims3.UI.Hud.FestivalTicketDialog::.ctor()', @{Floats = 50}),
						('System.Void Sims3.UI.HUD.HUDPerformanceCareerGigSchedule::.ctor()', @{Floats = 50}),
						('System.Void Sims3.UI.Hud.InteractionQueueItem::Layout(System.Single)', @{InstanceFields = 'mInteractionStyleWidths'; StaticFields = 'kProgressBarStretchableBaseWidth', 'kProgressBarStretchableTonesBaseWidth', 'kQueueButtonNormalHeight', 'kQueueButtonProgressHeight', 'kQueueButtonVerticalOffset'}),
						('System.Void Sims3.UI.Hud.InteractionQueueItem::UpdateInteractionBG()', @{StaticFields = 'kProgressBarNormalWidth', 'kProgressBarStretchableBaseWidth', 'kProgressBarStretchableTonesBaseWidth', 'kProgressBarTonesWidth'}),
						('System.Void Sims3.UI.Hud.InteractionQueueItem::UpdateProgressBar(Sims3.UI.Hud.IInteractionInstance)', @{StaticFields = 'kProgressBarNormalWidth', 'kProgressBarStretchableBaseWidth', 'kProgressBarStretchableTonesBaseWidth', 'kProgressBarTonesWidth'}),
						('System.Void Sims3.UI.Hud.InteractionQueueItem::UpdateDraggerWidth(System.Single)', @{InstanceFields = 'mInteractionStyleWidths'; StaticFields = 'kQueueDraggerSnapDistance'}),
						('System.Single Sims3.UI.Hud.InteractionQueueItem::UpdatePosition(System.Single,System.Single,System.Single)', @{Floats = 0.01; StaticFields = 'kQueueAcceleration', 'kQueueMovementSpeed'}),
						('System.Void Sims3.UI.Hud.InteractionQueue::UpdateQueue()', @{StaticFields = 'kQueueButtonHorizontalOffset'}),
						('System.Void Sims3.UI.Hud.InteractionQueue::UpdateQueueFull()', @{StaticFields = 'kQueueButtonHorizontalOffset'}),
						('System.Void Sims3.UI.Hud.OpportunitiesPanel::FillOpportunintyData(System.Int32,Sims3.UI.WindowBase)', @{Floats = 1}),
						('System.Void Sims3.UI.Hud.OpportunitiesPanel::Init()', @{Floats = 30}),
						('System.Void Sims3.UI.Hud.PieMenu::CreateSimHead(Sims3.SimIFace.ObjectGuid)', @{Floats = 128}),
						('System.Int32 Sims3.UI.Hud.PieMenu::GetButtonIndex(Sims3.SimIFace.Vector2)', @{Floats = 30}),
						('System.Void Sims3.UI.Hud.PieMenu::OnPickerPopulationFinished()', @{Floats = 4}),
						('Sims3.SimIFace.Rect Sims3.UI.Hud.PieMenu::SetupButton(Sims3.UI.Hud.MenuItem,System.UInt32,Sims3.SimIFace.Vector2,Sims3.SimIFace.Vector2)', @{Floats = 2, 4, 55}),
						('System.Void Sims3.UI.Hud.PieMenu::ComputeRadialLocations(Sims3.SimIFace.Vector2[]&,System.UInt32)', @{Floats = 80, 160}),
						('System.Void Sims3.UI.Hud.RelationshipsPanel::OnMouseMoveEvent(Sims3.UI.WindowBase,Sims3.UI.UIMouseEventArgs)', @{Floats = @{_ = 2; '?' = {Param ($OccurrenceIndex) $OccurrenceIndex -eq 0}}}),
						('System.Void Sims3.UI.Hud.RewardTraitsShopDialog::.ctor()', @{Floats = 50}),
						('System.Void Sims3.UI.Hud.SimDisplay::OnMotivesChanged(Sims3.UI.Hud.SimInfo)', @{Floats = 0.005}),
						('System.Void Sims3.UI.Hud.SimDisplay::UpdateQuestTracker(System.Boolean)', @{StaticFields = 'kQuestWindowInteractionButtonNoJournalButtonPosition', 'kQuestWindowInteractionButtonWithJournalPosition'}),
						('System.Void Sims3.UI.Hud.Skewer::PopulateHouseholdSkewer()', @{Floats = 60, 118}),
						('System.Void Sims3.UI.Hud.Skewer::PopulatePetSkewer()', @{Floats = 46, 100}),
						('System.Void Sims3.UI.Hud.SkillsPanel::OnMouseMoveEvent(Sims3.UI.WindowBase,Sims3.UI.UIMouseEventArgs)', @{Floats = 20}),
						('System.Void Sims3.UI.CelebrityTooltip::.ctor(System.String,System.UInt32)', @{Integers = 100}),
						('System.Void Sims3.UI.InfluentialCelebrityTooltip::.ctor(System.String,System.UInt32,System.Int32,System.Int32,System.Int32)', @{Integers = 100; StaticFields = 'kSocialGroupHeightBuffer'}),
						('System.Void Sims3.UI.MapTagCarTooltip::.ctor(System.String,System.Collections.Generic.List`1<Sims3.SimIFace.ObjectGuid>)', @{Floats = 10, 250}),
						('System.Void Sims3.UI.MapTagLotTooltip::.ctor(System.String,System.String,System.String,System.Collections.Generic.List`1<Sims3.SimIFace.ObjectGuid>)', @{Floats = 10, 250}),
						('System.Void Sims3.UI.MapTagRabbitHoleTooltip::.ctor(System.String,System.String,System.String,System.Collections.Generic.List`1<Sims3.SimIFace.ObjectGuid>,System.Boolean)', @{Floats = 10, 250}),
						('System.Boolean Sims3.UI.ObjectPicker::CreateRow(Sims3.UI.TableContainer,Sims3.UI.TableRow,System.Object)', @{Floats = @{_ = 20; Truncated = $True}}),
						('System.Void Sims3.UI.ObjectPicker::RepopulateHeaders()', @{Floats = 20; Integers = [UInt32] 20, [UInt32] 30, [UInt32] 32, 40, [UInt32] 40, 50, [UInt32] 50, [UInt32] 60, 65, 92, 100, 125, 150, 160, 200}),
						('System.Void Sims3.UI.ObjectPickerDialog::.ctor(System.Boolean,Sims3.UI.ModalDialog/PauseMode,System.String,System.String,System.String,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>,System.Int32,Sims3.SimIFace.Vector2,System.Boolean,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/RowInfo>,System.Boolean,System.Boolean)', @{Floats = 50, 64}),
						('System.Void Sims3.UI.OptionsMenu::.ctor()', @{Floats = 768; Integers = 33}),
						('Sims3.SimIFace.Vector2 Sims3.UI.PassportBookController::GetStampStartPos(System.Int32)', @{Floats = 110, 670, 790, 910}),
						('System.Void Sims3.UI.PopupMenu::.ctor(System.String[],Sims3.SimIFace.Vector2)', @{Integers = 33}),
						('System.Void Sims3.UI.PlayerProfileController::AddWallPosts()', @{Floats = 35, 64, 186}),
						('System.Void Sims3.UI.ProgressDialog::.ctor(System.String,Sims3.SimIFace.Vector2,Sims3.UI.ModalDialog/PauseMode,System.Boolean,System.Boolean,System.Boolean)', @{Floats = 200}),
						('System.Void Sims3.UI.RelationshipTooltip::.ctor(System.String,System.Single,System.String,System.String,System.UInt32)', @{Floats = 4}),
						('System.Void Sims3.UI.ScrollWindow::UpdateScrollBars(Sims3.SimIFace.Rect)', @{Floats = 15}),
						('System.Void Sims3.UI.SimpleTextTooltip::.ctor(System.String,System.Boolean,System.String,System.Int32)', @{Integers = 180}),
						('System.Void Sims3.UI.SimpleTextTooltip::UpdateTooltipText(System.String)', @{Floats = 1}),
						('Sims3.SimIFace.Vector2 Sims3.UI.SimpleTextTooltip::ResizeTooltipWidth(System.Int32)', @{Floats = 10}),
						('Sims3.SimIFace.Vector2 Sims3.UI.CelebrityTooltip::ResizeTooltipWidth(System.Int32)', @{Floats = 10}),
						('Sims3.SimIFace.Vector2 Sims3.UI.InfluentialCelebrityTooltip::ResizeTooltipWidth(System.Int32)', @{Floats = 10}),
						('System.Void Sims3.UI.InGameWallController::AddWallPosts()', @{Floats = 64, 186}),
						('System.Void Sims3.UI.InGameWallController::ShowIndividualPost(System.Object)', @{Floats = 5, 100, 110}),
						('System.Void Sims3.UI.InGameWallController::UpdateNews(System.Object)', @{Floats = 20}),
						('Sims3.UI.Tooltip Sims3.UI.TraitChipDialog/TraitChipDialogRowController::CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Integers = 320}),
						('System.Void Sims3.UI.StoreListNotification::Show()', @{Floats = 5}),
						('System.Void Sims3.UI.StyledNotification::Show()', @{StaticFields = 'kButtonPadding'}),
						('System.Void Sims3.UI.TableContainer::UpdateGridSize()', @{Floats = 1}),
						(
							'System.Void Sims3.UI.TableRelationshipController::set_ImageSize(System.Single)',
							@{
								Floats = & `
								{
									$FirstAfter8 = [ValueTuple[Bool]]::new($False)
									3
									@{
										'?' = `
										{
											Param ($Instruction)
											    if ($Instruction.Operand -eq [Float] 8) {$FirstAfter8.Item1 = $True; $True} `
											elseif ($FirstAfter8.Item1 -and $Instruction.Operand -eq [Float] 2) {$FirstAfter8.Item1 = $False; $True} `
											else {$False}
										}.GetNewClosure()
									}
								}
							}
						),
						('System.Void Sims3.UI.TableRelationshipController::set_Number(System.Single)', @{Floats = 35}),
						('System.Void Sims3.UI.AlchemyDialog/AlchemyDialogRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.AlchemyRecipeEntry,System.Boolean)', @{Floats = 31}),
						('System.Void Sims3.UI.DownloadDashboardInventoryRowController::set_ItemImageKey(Sims3.SimIFace.ResourceKey)', @{Floats = 90}),
						('System.Void Sims3.UI.DownloadDashboardInventoryRowController::UpdateItemThumbnail(System.Boolean)', @{Floats = 64}),
						('System.Void Sims3.UI.MoveDialogBase::AddItemGridItem(Sims3.UI.ItemGrid,Sims3.UI.CAS.ISimDescription,System.Boolean,System.Boolean)', @{Floats = 31}),
						('System.Void Sims3.UI.ObjectPicker/PickerRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.ObjectPicker/RowInfo)', @{Floats = 16, 32}),
						('System.Void Sims3.UI.PartyPickerDialog/PartyPickerRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.PhoneSimPicker/SimPickerInfo)', @{Floats = 16, 40}),
						('System.Void Sims3.UI.TripPlannerDialog::AddItemGridItem(Sims3.UI.ItemGrid,Sims3.UI.TripPlannerDialog/ISimTravelInfo,System.Boolean,System.Boolean)', @{Floats = 31}),
						('System.Void Sims3.UI.Dialogs.AnnounceProtestDialog/ProtestCauseRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.Dialogs.AnnounceProtestDialog/ProtestOptionData)', @{Floats = 40}),
						('System.Void Sims3.UI.Hud.CollectionJournalDialog/CollectableRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.Hud.CollectionRowInfo)', @{Floats = 24, 48}),
						('System.Void Sims3.UI.View.DualPaneSimPicker/DualPaneSimPickerRowController::.ctor(Sims3.UI.TableRow,Sims3.UI.TableContainer,Sims3.UI.PhoneSimPicker/SimPickerInfo)', @{Floats = 40}),
						('System.Collections.Generic.List`1<System.Object> Sims3.UI.PhoneSimPicker::Show(System.Boolean,Sims3.UI.ModalDialog/PauseMode,System.Collections.Generic.List`1<Sims3.UI.PhoneSimPicker/SimPickerInfo>,System.String,System.String,System.String,System.Int32,Sims3.SimIFace.Vector2,System.Boolean)', @{Integers = 40, 230}),
						('System.Void Sims3.UI.TableThumbAndMiniAndTextController::set_ImageSize(System.Single)', @{Floats = 3, 8}),
						('System.Void Sims3.UI.TableThumbAndTextController::set_ImageSize(System.Single)', @{Floats = 3, 8}),
						('System.Void Sims3.UI.TableThumbAndTwoTextController::set_ImageSize(System.Single)', @{Floats = 3, 8}),
						('System.Void Sims3.UI.TableThumbTextButtonController::set_ImageSize(System.Single)', @{Floats = 3, 8}),
						('System.Void Sims3.UI.TitleDescriptionTooltip::.ctor(System.String,System.String)', @{Integers = 180}),
						('Sims3.UI.Tooltip Sims3.UI.Hud.ActiveCareerPanel::CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Integers = 300}),
						('Sims3.UI.Tooltip Sims3.UI.Hud.CareerPanel::CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Integers = 300}),
						('System.Void Sims3.UI.TripPlannerDialog::.ctor(System.Collections.Generic.List`1<Sims3.UI.TripPlannerDialog/IDestinationInfo>,System.Collections.Generic.List`1<System.Int32>,System.Collections.Generic.List`1<Sims3.UI.TripPlannerDialog/ISimTravelInfo>,Sims3.UI.TripPlannerDialog/ISimTravelInfo,Sims3.UI.ModalDialog/PauseMode)', @{Floats = 1, 10, 180}),
						('System.Void Sims3.UI.TripPlannerDialog::UpdateSlider(System.Int32,System.Boolean)', @{Floats = 10, 20}),
						('Sims3.SimIFace.Vector2 Sims3.UI.TooltipManager::CalculateTooltipPosition(Sims3.SimIFace.Vector2)', @{StaticFields = 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.x', 'Sims3.UI.TooltipManager::TOOLTIP_OFFSET.y'}),

						('Sims3.SimIFace.Rect Sims3.UI.CAS.CASFamilyScreen::ConnectBounds(Sims3.SimIFace.Rect,Sims3.SimIFace.Rect,System.Boolean,Sims3.SimIFace.Color)', @{Floats = 1, 4, 5, 6; StaticFields = 'HORIZONTAL_BAR_INC'}),
						('Sims3.SimIFace.Rect Sims3.UI.CAS.CASFamilyScreen::ConnectBoundsH(Sims3.SimIFace.Rect,Sims3.SimIFace.Rect,System.Boolean,System.Boolean,Sims3.SimIFace.Color)', @{Floats = 1, 2}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::ConnectBoundsH(Sims3.SimIFace.Rect,Sims3.SimIFace.Rect,System.Boolean,Sims3.SimIFace.Color)', @{Floats = 1}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::ConnectBoundsV(Sims3.SimIFace.Rect,Sims3.SimIFace.Rect,System.Boolean,Sims3.SimIFace.Color)', @{Floats = 1}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::ConnectSims(Sims3.UI.SimTreeInfo,Sims3.UI.SimTreeInfo,System.Boolean,System.Boolean,System.Boolean,Sims3.SimIFace.Color)', @{Floats = 1, 4, 5}),
						('Sims3.SimIFace.Rect Sims3.UI.CAS.CASFamilyScreen::RecurseLayoutDescendants(Sims3.UI.CAS.CASFamilyScreen/SimTreeInfo,System.Single,System.Single)', @{StaticFields = 'Y_DIST_BETWEEN_THUMBS'}),
						('System.Void Sims3.UI.CAS.CASFamilyScreen::RefreshFamily()', @{StaticFields = 'Y_DIST_BETWEEN_THUMBS'}),
						('System.Void Sims3.UI.FamilyTreeDialog::Layout(System.Int32,System.Int32)', @{Floats = 1, 10; StaticFields = 'X_DIST_BETWEEN_THUMBS', 'Sims3.UI.FamilyTreeThumb::kRegularArea.x'}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::GenericLayoutParents(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,Sims3.UI.SimTreeInfo,System.Boolean,System.Boolean)', @{StaticFields = 'X_DIST_BETWEEN_THUMBS'}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::RecurseLayoutParents(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,System.Int32)', @{StaticFields = 'X_DIST_BETWEEN_THUMBS', 'Y_DIST_BETWEEN_THUMBS', 'Sims3.UI.FamilyTreeThumb::kRegularArea.x', 'Sims3.UI.FamilyTreeThumb::kRegularArea.y'}),
						('Sims3.SimIFace.Rect Sims3.UI.FamilyTreeDialog::RecurseLayoutChildren(System.Int32,System.Int32,Sims3.UI.SimTreeInfo,Sims3.UI.SimTreeInfo,System.Int32,System.Boolean,System.Boolean)', @{StaticFields = 'X_DIST_BETWEEN_THUMBS', 'Y_DIST_BETWEEN_THUMBS', 'Sims3.UI.FamilyTreeThumb::kRegularArea.x'}),
						('System.Void Sims3.UI.FamilyTreeDialog::RefreshTree(Sims3.UI.CAS.IMiniSimDescription)', @{Floats = 15; Integers = 5; StaticFields = 'BUFFER', 'SCROLL_BUFFER', 'MIN_WIDTH', 'MIN_HEIGHT'}),
						('System.Void Sims3.UI.FamilyTreeThumb::set_SelectedThumb(System.Boolean)', @{StaticFields = 'Sims3.UI.FamilyTreeThumb::kRegularArea.x', 'Sims3.UI.FamilyTreeThumb::kRegularArea.y', 'Sims3.UI.FamilyTreeThumb::kSelectedArea.x', 'Sims3.UI.FamilyTreeThumb::kSelectedArea.y'}),
						('System.Void Sims3.UI.Hud.AdventureRewardsShopDialog::CompletePurchase(System.Int32,Sims3.UI.Hud.AdventureRewardStoreInventoryRowController,Sims3.UI.Hud.IUIAdventureReward)', @{Floats = 10}),
						('System.Void Sims3.UI.Hud.AdventureJournalDialog::.ctor()', @{Floats = 10}),
						('System.Void Sims3.UI.Hud.FestivalTicketDialog::CompletePurchase(System.Int32,Sims3.UI.Hud.FestivalTicketInventoryRowController,Sims3.UI.Hud.IUIFestivalTicketReward)', @{Floats = 10}),
						('System.Void Sims3.UI.Hud.OpportunitiesPanel::OnHouseholdAncientCoinCountChanged(System.Int32,System.Int32)', @{Floats = 10, 50}),
						('System.Void Sims3.UI.Hud.OpportunityDialog::BeginZoop()', @{Floats = 10, 50}),
						('System.Void Sims3.UI.Hud.RewardTraitsPanel::StartWishFulfilledZoop(Sims3.UI.Hud.IDreamAndPromise)', @{Floats = 10, 50}),
						('System.Void Sims3.UI.Hud.RewardTraitsShopDialog::CompletePurchase(System.Int32,Sims3.UI.Hud.RewardTraitStoreInventoryRowController,Sims3.UI.Hud.RewardTraitAdditionResult)', @{Floats = 10}),
						('System.Void Sims3.UI.BlogAppDialog::OnTick(Sims3.UI.WindowBase,Sims3.UI.UIEventArgs)', @{StaticFields = 'kTickerTextRate'}),
						('System.Void Sims3.UI.BuyController::OnTogglePageClicked(Sims3.UI.WindowBase,Sims3.UI.UIButtonClickEventArgs)', @{Floats = 51}),
						('System.Void Sims3.UI.CAS.CAP.CAPCharacter::UpdateTraitIconPositions()', @{Floats = @{_ = 0.5; '?' = {Param ($OccurrenceIndex) $OccurrenceIndex -eq 3}}}),
						('System.Void Sims3.UI.CAS.CASCharacter::UpdateTraitIconPositions()', @{Floats = @{_ = 0.5; '?' = {Param ($OccurrenceIndex) $OccurrenceIndex -eq 3}}}),
						('System.Void Sims3.UI.CAS.CASClothingCategory::HideUnusedIcons()', @{Floats = -3, 39, 42, 159}),
						('System.Void Sims3.UI.CAS.CASHair::HideUnusedIcons()', @{Floats = -2, 40, 42, 210}),
						('System.Void Sims3.UI.CAS.CASMakeup::HideUnusedIcons()', @{Floats = -3, 39, 42, 110}),
						('System.Void Sims3.UI.CAS.CASRequiredItemsDialog::UpdateTraitIconPositions()', @{Floats = @{_ = 0.5; '?' = {Param ($OccurrenceIndex) $OccurrenceIndex -eq 3}}}),
						('System.Void Sims3.UI.Hud.ActiveCareerPanel::UpdateDaysofWeek()', @{Floats = -35}),
						('System.Void Sims3.UI.Hud.InteractionQueueItem::ToneSelectionChange(Sims3.UI.WindowBase,Sims3.UI.UISelectionChangeEventArgs)', @{StaticFields = 'kGreyedOutTooltipOffset'}),
						('System.Void Sims3.UI.Hud.MapviewHoverButton::OnCameraAtMaxZoom(System.Boolean)', @{StaticFields = 'kOffsetFromMouseCursor'}),
						('System.Void Sims3.UI.Hud.SimDisplay::CheckSkewerDisplacement()', @{StaticFields = 'kSkewerDisplacement', 'kSkewerPadding'}),
						('System.Void Sims3.UI.ScreenGrabController::UpdateCameraParameters()', @{Floats = 10}),
						('System.Boolean Sims3.UI.ScreenGrabController::Init(System.UInt32,System.UInt32,System.UInt32,System.UInt32)', @{Floats = 1024, 768}),
						('Sims3.UI.Tooltip Sims3.UI.TraitsPickerDialog::CreateTraitsTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Floats = 10}),
						('Sims3.UI.Tooltip Sims3.UI.TraitsPickerDialog::CreateAppliedTraitsTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Floats = 10, 60, 120}),
						('Sims3.UI.Tooltip Sims3.UI.WishPickerDialog::CreateWishesTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Floats = 10, 60, 120}),
						('Sims3.UI.Tooltip Sims3.UI.Hud.OpportunitiesPanel::CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Floats = 30})
					)
				}

				$TinyUIFixPSForTS3ResourceKeys.Sims3GameplaySystemsDLL = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'Sims3.Gameplay.Objects '
					Patches = (
						('Sims3.Gameplay.Objects.FoodObjects.Recipe Sims3.Gameplay.Objects.Vehicles.FoodTruckBase/OrderFood::ShowBuyFoodDialog()', @{Integers = 200}),
						('Sims3.Gameplay.Objects.FoodObjects.Recipe Sims3.Gameplay.Objects.Vehicles.IceCreamTruck/OrderIceCream::ShowBuyFoodDialog()', @{Integers = 200}),
						('Sims3.Gameplay.Objects.Vehicles.Vehicle/VehicleInfo Sims3.Gameplay.Objects.Vehicles.Vehicle::ShowBuyDialog(Sims3.Gameplay.Actors.Sim,Sims3.Gameplay.Interfaces.ISupportsBuyingVehicles)', @{Integers = 200}),
						('System.Boolean Sims3.Gameplay.ActorSystems.OccultGenie/MakeWish::MakeSimLoveMe()', @{Integers = 500}),
						('System.Boolean Sims3.Gameplay.ActorSystems.OccultGenie/MakeWish::RessurectSim()', @{Integers = 500}),
						('System.Boolean Sims3.Gameplay.Objects.Fishing.Fish/FishDonatableDefinition::CustomAction(Sims3.Gameplay.ObjectComponents.IDonatableDefinition)', @{Integers = 256}),
						('System.Boolean Sims3.Gameplay.Skills.Bartending/NameDrinkAfterSim::Run()', @{Integers = 256}),
						('System.Boolean Sims3.Gameplay.Skills.Bartending/NameDrinkAfterSim::Run()', @{Integers = 92}),
						('System.Collections.Generic.List`1<Sims3.Gameplay.Actors.Sim> Sims3.Gameplay.Actors.Sim/CreateStudyGroup::PopPicker(System.Collections.Generic.List`1<Sims3.Gameplay.Actors.Sim>)', @{Integers = 230}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Bartending::HeaderInfo(System.Int32)', @{Integers = 225, 384}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Bartending::HeaderInfo(System.Int32)', @{Integers = 90}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Bartending::HeaderInfo(System.Int32)', @{Integers = 90}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.BotBuildingSkill::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.BotBuildingSkill::HeaderInfo(System.Int32)', @{Integers = 102}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.BotBuildingSkill::HeaderInfo(System.Int32)', @{Integers = 80}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Consignment::HeaderInfo(System.Int32)', @{Integers = 125}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Consignment::HeaderInfo(System.Int32)', @{Integers = 275}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Cooking::HeaderInfo(System.Int32)', @{Integers = 102}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Cooking::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Cooking::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Cooking::HeaderInfo(System.Int32)', @{Integers = 115}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Fishing::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Fishing::HeaderInfo(System.Int32)', @{Integers = 160}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Fishing::HeaderInfo(System.Int32)', @{Integers = 130}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Fishing::HeaderInfo(System.Int32)', @{Integers = 130}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Gardening::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Handiness::HeaderInfo(System.Int32)', @{Integers = 125}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Handiness::HeaderInfo(System.Int32)', @{Integers = 275}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.InventingSkill::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.InventingSkill::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.InventingSkill::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.InventingSkill::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.InventingSkill::HeaderInfo(System.Int32)', @{Integers = 80}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Jumping::HeaderInfo(System.Int32)', @{Integers = 50}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Jumping::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Jumping::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Jumping::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Jumping::HeaderInfo(System.Int32)', @{Integers = 180}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.LogicSkill::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.LogicSkill::HeaderInfo(System.Int32)', @{Integers = 170}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.LogicSkill::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.LogicSkill::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.NectarSkill::HeaderInfo(System.Int32)', @{Integers = 275}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.NectarSkill::HeaderInfo(System.Int32)', @{Integers = 125}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Photography::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Photography::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Photography::HeaderInfo(System.Int32)', @{Integers = 60}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Racing::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Racing::HeaderInfo(System.Int32)', @{Integers = 70}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Racing::HeaderInfo(System.Int32)', @{Integers = 180}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Racing::HeaderInfo(System.Int32)', @{Integers = 50}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Racing::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.RidingSkill::HeaderInfo(System.Int32)', @{Integers = 180}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.RidingSkill::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.RidingSkill::HeaderInfo(System.Int32)', @{Integers = 180}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.RockBand::HeaderInfo(System.Int32)', @{StaticFields = 'kColumnWidthSize'}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.SpellcraftSkill::HeaderInfo(System.Int32)', @{Integers = 80}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.SpellcraftSkill::HeaderInfo(System.Int32)', @{Integers = 102}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.SpellcraftSkill::HeaderInfo(System.Int32)', @{Integers = 200}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Writing::HeaderInfo(System.Int32)', @{Integers = 120}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Writing::HeaderInfo(System.Int32)', @{Integers = 160}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo> Sims3.Gameplay.Skills.Writing::HeaderInfo(System.Int32)', @{Integers = 155}),
						('System.Void Sims3.Gameplay.ActiveCareer.ActiveCareers.SingerCareer/PerformSong/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Gameplay.ActiveCareer.AddActiveCareer/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Actors.Sim/AddBuff/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Actors.Sim/DEBUG_PlayReaperAnim/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 50, 230}),
						('System.Void Sims3.Gameplay.Actors.Sim/FeedHarvestable::PopulateHarvestablePicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Actors.Sim/GoForWalkWithDog/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Actors.Sim/OfferBug/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.ActorSystems.OccultFairy/PickNewWings/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 6, 230}),
						('System.Void Sims3.Gameplay.ActorSystems.OccultGenie/SummonFood/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Gameplay.Careers.SkillBasedCareer/AddSkillBasedCareer/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Core.Mailbox/ReturnStolenItem/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.ObjectComponents.DonatableComponent/DonateInteraction`1/Definition`1::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.ObjectComponents.TreasureComponent/SetTreasureInfo/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 32, 500}),
						('System.Void Sims3.Gameplay.Objects.Bookshelf_ReadToToddler/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Fishing.FishWithSelectedBait/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 210}),
						('System.Void Sims3.Gameplay.Objects.FoodObjects.Herb::PopulatePickerWithHerbs(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Objects.Gardening.OmniPlant/Feed/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 215}),
						('System.Void Sims3.Gameplay.Objects.Gardening.Plant/FertilizePlant/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 170}),
						('System.Void Sims3.Gameplay.Objects.Island.Houseboat/DEBUG_SetHouseboatLot/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Island.Houseboat/DEBUG_SetPortLotTo/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Misc.MosquitoRepellent/SpraySim/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.FacePaintingBooth/GetPainted/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 210}),
						('System.Void Sims3.Gameplay.OnlineGiftingSystem.OnlineGiftingManager::DEBUG_ShowGiftPicker(System.String,System.Boolean)', @{Integers = 64}),
						('System.Void Sims3.Gameplay.OnlineGiftingSystem.OnlineGiftingManager::DEBUG_ShowGiftPicker(System.String,System.Boolean)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Skills.DEBUG_AddSkillOrSetLevel/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Skills.DEBUG_AddSkillOrSetLevel/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo> Sims3.Gameplay.Skills.NectarSkill::get_SecondaryTabs()', @{Integers = 50}),
						('System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo> Sims3.Gameplay.Skills.Writing::get_SecondaryTabs()', @{Integers = 50}),
						('System.Void Sims3.Gameplay.Interactions.InteractionDefinition`3::PopulateSimPicker(Sims3.Gameplay.Actors.Sim,Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Collections.Generic.List`1<Sims3.Gameplay.Actors.Sim>,System.Boolean,System.Boolean)', @{Integers = 40, 230}),
						('System.Void Sims3.Gameplay.Interactions.InteractionDefinition`3::PopulateSimPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Collections.Generic.List`1<Sims3.Gameplay.CAS.SimDescription>,System.Boolean,System.Collections.Generic.List`1<Sims3.Gameplay.Interactions.InteractionDefinition`3/SimPickerAdditionalTextColumn<TActor,TTarget,TInteraction>>)', @{Integers = 40, 230, 270}),
						('System.Void Sims3.Gameplay.Objects.Bookshelf_Read/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.TownieMaker::BuildSimPicker(System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Collections.Generic.List`1<Sims3.Gameplay.CAS.SimDescription>)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Actors.Sim/GiveGift/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Gameplay.UI.HudModel::ShowDegreePicker(Sims3.Gameplay.Actors.Sim,System.Object)', @{Integers = 230}),

						('System.Void Sims3.Gameplay.CAS.OutfitUtils::PopulatePieMenuPickerWithOutfits(Sims3.Gameplay.Actors.Sim,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&,Sims3.Gameplay.CAS.OutfitUtils/GreyedOutOutfitCallback)', @{Integers = 50, 250}),
						('System.Void Sims3.Gameplay.CelebritySystem.DeflectScandal/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 120}),
						('System.Void Sims3.Gameplay.CelebritySystem.NameDrop/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 120}),

						<# Why is this in GameplaySystems? EA, what are you doing? #>
						('System.Void Sims3.Gameplay.UI.MovingWorldDialog::PopulateWorldFileComboBox()', @{Floats = 15, 27, 205, 227}),

						<# You already have a colour-picker in UI! EA, what are you doing?! #>
						('System.Boolean Sims3.Gameplay.UI.ColorWheelSelector::UpdateSelectorPosition()', @{Floats = 10}),
						('System.Boolean Sims3.Gameplay.UI.ColorWheelSelector::UpdateSelectorPosition(Sims3.SimIFace.Vector2)', @{Floats = 3, 10, 75}),
						('System.Void Sims3.Gameplay.UI.ColorWheelSelector::ColorFromPoint(Sims3.SimIFace.Vector2,System.Single&,System.Single&,System.Single&)', @{Floats = 75}),
						('Sims3.SimIFace.Vector2 Sims3.Gameplay.UI.ColorWheelSelector::PointFromColor(System.Single,System.Single)', @{Floats = 75}),
						('Sims3.SimIFace.Vector3[] Sims3.Gameplay.UI.ColorWheelSelector::GetCompoundColors(System.Single,System.Single,System.Single,Sims3.SimIFace.Vector2[]&)', @{Floats = 75}),
						('Sims3.SimIFace.Vector3[] Sims3.Gameplay.UI.ColorWheelSelector::GetTriadColors(System.Single,System.Single,System.Single,Sims3.SimIFace.Vector2[]&)', @{Floats = 75}),
						('Sims3.SimIFace.Vector3[] Sims3.Gameplay.UI.ColorWheelSelector::GetAnalogousColors(System.Single,System.Single,System.Single,Sims3.SimIFace.Vector2[]&)', @{Floats = 75}),

						('System.Boolean Sims3.Gameplay.Objects.Vehicles.Vehicle/BuyVehicleFromISupportsBuyingVehicles::Run()', @{Floats = 10, 150})
					)
				}

				$TinyUIFixPSForTS3ResourceKeys.Sims3GameplayObjectsDLL = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'Sims3.Gameplay'
					Patches = (
						('System.Void Sims3.Gameplay.Objects.Electronics.Computer/PurchaseWrittenBooks/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 50, 230}),

						('Sims3.Gameplay.Objects.Electronics.Jukebox/SongData Sims3.Gameplay.Objects.Electronics.Jukebox/ChangeSong::ShowChangeSongDialog()', @{Integers = 200}),
						('Sims3.Gameplay.Objects.FoodObjects.Recipe Sims3.Gameplay.Objects.Register.ShoppingRegister::ShowBuyFoodDialog(Sims3.Gameplay.Actors.Sim)', @{Integers = 200}),
						('Sims3.Gameplay.Objects.Urnstone Sims3.Gameplay.Objects.Alchemy.PhilosopherStone/BindGhost::PopPicker(System.Collections.Generic.List`1<Sims3.Gameplay.Objects.Urnstone>)', @{Integers = 230}),
						('System.Collections.Generic.List`1<Sims3.Gameplay.Interfaces.IGameObject> Sims3.Gameplay.Objects.HobbiesSkills.GemCuttingMachine/CutGemWithMachine::ShowGemSelectionDialog()', @{Integers = 250}),
						('System.Collections.Generic.List`1<Sims3.Gameplay.Interfaces.IGameObject> Sims3.Gameplay.Objects.HobbiesSkills.GemCuttingMachine/CutGemWithMachine::ShowGemSelectionDialog()', @{Integers = 250}),
						('System.Collections.Generic.List`1<Sims3.Gameplay.Objects.ScientificSample> Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation::ShowSingleSampleSelectionDialog(Sims3.Gameplay.Actors.Sim,System.String,System.String,System.String,System.String,System.String,Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation/SelectionDelegate)', @{Integers = 250}),
						('System.Collections.Generic.List`1<Sims3.Gameplay.Objects.ScientificSample> Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation::ShowSingleSampleSelectionDialog(Sims3.Gameplay.Actors.Sim,System.String,System.String,System.String,System.String,System.String,Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation/SelectionDelegate)', @{Integers = 250}),
						('System.Collections.Generic.List`1<T> Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation::ShowItemStackSelectionDialog(Sims3.Gameplay.Actors.Sim,System.String,System.String,System.String,System.String,System.String,Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation/SelectionDelegate)', @{Integers = 250}),
						('System.Collections.Generic.List`1<T> Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation::ShowItemStackSelectionDialog(Sims3.Gameplay.Actors.Sim,System.String,System.String,System.String,System.String,System.String,Sims3.Gameplay.Objects.HobbiesSkills.ScienceResearchStation/SelectionDelegate)', @{Integers = 250}),
						('System.Boolean Sims3.Gameplay.Objects.Miscellaneous.FestivalTicket::GrantFestivalTickets(Sims3.Gameplay.Actors.Sim,System.Int32)', @{Floats = 100}),
						('System.UInt16 Sims3.Gameplay.Objects.Miscellaneous.Shopping.BaseFoodStand::ShowBuyFoodDialog(Sims3.Gameplay.Actors.Sim)', @{Integers = 200}),
						('System.Void Sims3.Gameplay.Objects.CookingObjects.Cake/HaveBirthdayFor/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Objects.Counters.BarAdvanced::PopulatePickerWithNectar(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Objects.Decorations.BirdCage/TeachToTalk/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Decorations.DigitalFishTank/RemoveFish/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Objects.Decorations.DigitalFishTank/Stock/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Objects.Electronics.Computer/HackOntoClubListing/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 210}),
						('System.Void Sims3.Gameplay.Objects.Electronics.Computer/PurchaseWrittenBooks/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Gameplay.Objects.Electronics.TV::PopulatePiePickerForDataDiscs(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Environment.Sandbox/BuryObject/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.MinorPets.MinorPetTerrarium/PutAway/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.TreasureChestEP10/AssignTreasure/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.TreasureChestEP10/AssignTreasure/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.TreasureChestEP10/AssignTreasure/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.TreasureChestEP10/AssignTreasure/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Void Sims3.Gameplay.Objects.Miscellaneous.TreasureChestEP10/AssignTreasure/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 150}),
						('System.Void Sims3.Gameplay.Objects.Pets.PetBowl/FeedPetGourmet/FeedGourmetDefinition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 210}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.MovieSet/SellScriptChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 125}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.MovieSet/SellScriptChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 215}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellInsectChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 215}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellInsectChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 125}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellSamplesChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 215}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellSamplesChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 125}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellSpiritChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 215}),
						('System.Void Sims3.Gameplay.Objects.RabbitHoles.ScienceLab/SellSpiritChoose/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 125}),
						('System.Void Sims3.Gameplay.Objects.TombObjects.TreasureChest/SetTreasureChestInfo/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Boolean Sims3.Gameplay.Objects.Beds.BedDreamPod::ShowDreamSelectionDialog(Sims3.Gameplay.Actors.Sim,Sims3.Gameplay.Actors.Sim,Sims3.Gameplay.Interfaces.DreamIdentification&)', @{Integers = 256}),
						('System.Void Sims3.Gameplay.Objects.Decorations.FishTank/Stock/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256})
					)
				}

				$TinyUIFixPSForTS3ResourceKeys.Sims3StoreObjectsDLL = @{
					TinyUIFixForTS3IntegrationTypeNamespace = 'Sims3.Store.Objects'
					Patches = (
						('Sims3.UI.Tooltip Sims3.Store.Objects.Turnstile::CreateTooltip(Sims3.SimIFace.Vector2,Sims3.UI.WindowBase,Sims3.SimIFace.Vector2&)', @{Integers = 400}),
						('System.Void Sims3.Store.Objects.BabyDragon/DEBUG_SetDragonType/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Store.Objects.ChocolateFountain/ChangeChocolate/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Store.Objects.IceCreamMaker/MakeIceCream/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Store.Objects.IceCreamMaker/RemoveCustomFlavor/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Store.Objects.IndustrialOven/FixQuickMeal/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Store.Objects.IndustrialOven/Menu/OrderFood/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Store.Objects.IndustrialOven/SetMenuChoices/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 500}),
						('System.Void Sims3.Store.Objects.LemonadeStand/Purchase/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 256}),
						('System.Void Sims3.Store.Objects.SpellBook/CastSpell/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230}),
						('System.Void Sims3.Store.Objects.Tablet::PopulateAudioPrograms(Sims3.Gameplay.Actors.Sim,Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Store.Objects.Tablet/ChooseBookOnTablet/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Store.Objects.TreeOfProsperity::PopulateImbueTypes(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 250}),
						('System.Void Sims3.Store.Objects.VoodooDoll/Bind/Definition::PopulatePieMenuPicker(Sims3.Gameplay.Interactions.InteractionInstanceParameters&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/TabInfo>&,System.Collections.Generic.List`1<Sims3.UI.ObjectPicker/HeaderInfo>&,System.Int32&)', @{Integers = 230})
					)
				}
			}

			$PatchCount = ($ConvenientPatches.Values.ForEach{$_.Patches.Count} | Measure-Object -Sum).Sum
			$State.Logger.WriteInfo("Applying $($PatchCount + 1) patches to the vanilla core DLLs.")

			$ConvenientlyAppliedPatches = Apply-ConvenientPatchesToAssemblies $ConvenientPatches $State.Assemblies.Resolver $State.Assemblies.AssemblyKeysByResourceKey

			$TinyUIFixForTS3IntegrationType = $UI.MainModule.GetType('Sims3.UI.TinyUIFixForTS3Integration')
			$GetUIScale = Find-StaticField $TinyUIFixForTS3IntegrationType getUIScale
			$GetUIScaleType = $GetUIScale.FieldType.Resolve()
			$GetUIScaleInvoke = Find-InstanceMethod $GetUIScaleType Invoke

			$ScaleFloatOnStack = `
			{
				[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Ldsfld, $GetUIScale)
				[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Callvirt, $GetUIScaleInvoke)
				[Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Mul)
			}

			Edit-MethodBody (Find-MethodByFullyQualifiedName $UI.MainModule 'System.Void Sims3.UI.TableContainer::UpdateGridSize()') `
			{
				do
				{
					if ($Instruction.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Ldfld -and $Instruction.Operand.FullName -ceq 'System.Boolean Sims3.UI.TableContainer::mbAddColumnDivider')
					{
						$LoadsMbAddColumnDivider = $Instruction

						if ($LoadsMbAddColumnDivider.Next.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Cond_Branch)
						{
							$Branch = $LoadsMbAddColumnDivider.Next

							if (Test-InstructionIsLdcI4 $Branch.Next -OfAnyOf 0, 1)
							{
								$LoadsInteger = $Branch.Next

								if ($LoadsInteger.Next.OpCode.FlowControl -eq [Mono.Cecil.Cil.FlowControl]::Branch)
								{
									$Jump = $LoadsInteger.Next

									if ($Jump.Operand.OpCode.Code -eq [Mono.Cecil.Cil.Code]::Conv_R4)
									{
										$AfterConditional = $Jump.Operand

										$Instruction = & $ScaleFloatOnStack | Append-Instruction -To $AfterConditional -IL $IL
									}
								}
							}
						}
					}
				}
				while ($Instruction = $Instruction.Next)
			}

			@{PatchedAssemblies = $ConvenientlyAppliedPatches}
		}
	}
}

