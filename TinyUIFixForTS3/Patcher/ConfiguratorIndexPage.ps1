
<# SPDX-LICENSE-IDENTIFIER: BSL-1.0 #>

<#
	Copyright Harry Gillanders 2023-2023.
	Distributed under the Boost Software License, Version 1.0.
	(See accompanying file LICENSE_1_0.txt or copy at https://www.boost.org/LICENSE_1_0.txt)
#>


Param ($State)

$MinimumPatchsetLoadOrderPosition = 2

@"
<!DOCTYPE html>
<html class="no-margin fill-container" lang="en-IE">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=240, initial-scale=1">
		<title>Tiny UI Fix for The Sims 3 | Configurator</title>

		<style>
			[hidden]
			{
				display: none !important;
			}

			figure, p, h1, h2, h3, h4, h5
			{
				margin: 0px;
			}

			fieldset
			{
				border-width: 0px;
				padding: 0;
				margin: 0;
			}

			a:not(.link)
			{
				text-decoration: none;
				color: inherit;
			}

			hr
			{
				color: inherit;
			}

			label.checkbox > :first-child
			{
				display: flex;
				column-gap: 0.1rem;
				align-items: center;
			}

			input, textarea
			{
				background-color: rgb(246, 250, 255);
			}

			.label-grid
			{
				display: grid;
				grid-template-columns: max-content 1fr max-content;
				column-gap: 0.4rem;
			}

			.label-grid > label
			{
				display: contents;
			}

			label-grid > label > :nth-child(1)
			{
				grid-column: 1;
			}

			label-grid > label > :nth-child(2)
			{
				grid-column: 2;
			}

			label-grid > label > :nth-child(2)
			{
				grid-column: 3;
			}

			.with-units
			{
				display: flex;
				column-gap: 0.6ch;
			}

			.no-margin
			{
				margin: 0px;
			}

			.fill-container
			{
				height: 100%;
				min-height: 100%;
				width: 100%;
				min-width: 100%;
			}

			.document
			{
				font-family: system-ui, sans-serif;
				background-color: rgb(19, 29, 72);
				color: rgb(215, 242, 249);
			}

			.viewable-body
			{
				display: flex;
			}

			.configurator
			{
				width: 100%;
				display: flex;
				flex-direction: column;
			}

			.configurator > header
			{
				display: flex;
				flex-direction: column;
				justify-content: start;
				align-items: center;

				row-gap: 1rem;

				padding-top: 1ex;
				padding-bottom: 1ex;
			}

			.configurator > header .panel
			{
				font-size: 140%;
			}

			.configurator-contents
			{
				flex-grow: 1;
				overflow-y: auto;

				display: flex;

				margin-left: 1.4rem;
				margin-right: 1.4rem;
			}

			.configurator-contents > section
			{
				padding-left: 0.6rem;
				padding-right: 0.6rem;
				padding-top: 0.6rem;
				padding-bottom: 0.8rem;
			}

			.configurator-contents > section, .configurator-contents > footer
			{
				overflow: auto;

				min-width: min-content;

				display: flex;
				flex-direction: column;

				row-gap: 1ex;

				margin-top: 0.4rem;
				margin-bottom: 0.8rem;
				margin-left: 0.2rem;
				margin-right: 0.2rem;
			}

			.configurator-contents > footer
			{
				min-width: 10%;
			}

			.configurator-contents > footer button
			{
				font-size: 110%;
			}

			.panel, .panel::-webkit-scrollbar
			{
				display: flex;
				flex-direction: column;
				row-gap: 0.6ex;

				background-color: rgb(150, 201, 255);
				color: rgb(41, 53, 89);
				padding: 0.6rem;
				border: solid 1px rgb(40, 64, 121);
				border-radius: 6px;

				scrollbar-color: rgb(130, 154, 218) rgb(62, 80, 136);
			}

			.panel.scrollable
			{
				overflow: auto;
			}

			.textual-panel
			{
				background-color: rgb(207, 235, 255);
				padding: 0.24rem;
				border: solid 1.4px rgb(41, 53, 89);
				border-radius: 8px;
			}

			.available-patchsets-list, .patchset-load-order-list
			{
				display: flex;
				flex-direction: column;

				row-gap: 0.2rem;

				margin: 0;
				padding: 0;
			}

			.available-patchsets-list > li
			{
				overflow-x: auto;

				display: flex;
				flex-direction: column;

				list-style: none;
			}

			.available-patchsets-list > li > :nth-child(1)
			{
				display: flex;
				justify-content: space-between;
			}

			.available-patchsets-list > li > :nth-child(1) > :nth-child(1)
			{
				font-size: 100%;
			}

			.available-patchsets-list > li > :nth-child(1) > :nth-child(2)
			{
				font-size: 90%;
				font-weight: bold;
			}

			.available-patchsets-list > li > :nth-child(2)
			{
				flex-grow: 1;

				max-height: 12ch;
				overflow-y: auto;
			}

			.available-patchsets-list > li > :nth-child(3)
			{
				display: flex;
				justify-content: end;
			}

			.available-patchsets-list > li > :nth-child(3) > :nth-child(1)
			{
				font-weight: 600;
				margin-right: auto;
			}

			.available-patchsets-list > li > :nth-child(3) > :nth-child(2), .available-patchsets-list > li > :nth-child(3) > :nth-child(3)
			{
				white-space: nowrap;
			}

			.available-patchsets-list > li > :nth-child(1), .available-patchsets-list > li > :nth-child(3)
			{
				column-gap: min(2ch, 1.4vw);
			}

			#patchset-load-order
			{
				min-width: 30vw;
			}

			#patchset-load-order .panel
			{
				font-size: 75%;
			}

			.patchset-load-order-list > li
			{
				display: flex;

				list-style: none;

				column-gap: 0.3rem;
			}

			.patchset-load-order-list > li > :nth-child(1), .patchset-load-order-list > li > :nth-child(2)
			{
				display: flex;

				align-items: center;
			}

			.patchset-load-order-list > li > :nth-child(1)
			{
				column-gap: 0.2rem;
			}

			.patchset-load-order-list > li > :nth-child(1) > input
			{
				width: 4ch;
				font-size: inherit;
			}

			.patchset-load-order-list > li > :nth-child(2)
			{
				flex-wrap: wrap;
				flex-grow: 1;
				column-gap: 0.2rem;
			}

			.patchset-load-order-list > li > :nth-child(2) > span
			{
				border-left: solid 1.2px rgb(41, 53, 89);
				padding-left: 0.2rem;
			}

			.import-export-zone-panel
			{
				flex-grow: 1;

				display: flex;
				flex-direction: column;

				row-gap: 0.8ex;
			}

			.import-export-zone-panel > h3
			{
				text-align: center;
			}

			.import-export-zone-panel > textarea
			{
				width: auto;
				height: 50%;
				resize: vertical;

				white-space: pre;
				font-family: monospace, monospace;
				font-size: 70%;
			}
		</style>

		<script>
			const patchsetID = 0;
			const patchsetName = 1;
			const patchsetVersion = 2;
			const patchsetActive = 3;
			const patchsetFixedActiveState = 4;

			const minimumPatchsetLoadOrderPosition = $MinimumPatchsetLoadOrderPosition;

			const availablePatchsets = $(ConvertTo-JSON ($State.AvailablePatchsets | % {,$($_.ID; $_.Name; $_.Version.ToString(); [Int32] $_.Active; [Int32] $_.FixedActiveState)}));
			const availablePatchsetsByID = new Map();

			for (const patchset of availablePatchsets)
			{
				availablePatchsetsByID.set(patchset[patchsetID], patchset);
			}

			const parseLoadOrderText = text =>
			{
				const loadOrder = ['Nucleus'];
				const encountered = new Set(loadOrder);

				for (const id of text.split(/\s+/g))
				{
					if (!encountered.has(id) && availablePatchsetsByID.has(id))
					{
						loadOrder.push(id);
						encountered.add(id);
					}
				}

				return {array: loadOrder, set: encountered};
			};

			const sendRequest = (path, body, onResponse = response => {}) =>
			{
				return fetch(
					path,
					{
						method: 'POST',
						headers: {'Content-Type': 'application/json'},
						body: JSON.stringify(body)
					}
				).then(
					response =>
					{
						if (response.status !== 204)
						{
							window.alert('The PowerShell script responded, but an error occurred. Please refer back to the script\'s output for more information.');

							return;
						}

						return onResponse(response);
					}
				).catch(
					error => window.alert(``The PowerShell script failed to respond.\n\n`${error}``)
				);
			}

			const initialiseDocument = () =>
			{
				const configurator = document.getElementById('configurator')
				const configuratorHeaderStatusMessageParent = configurator.querySelector('[data-header-status-message-parent]');
				const configuratorHeaderStatusMessage = configuratorHeaderStatusMessageParent.querySelector('[data-header-status-message]');
				const availablePatchsetsList = configurator.querySelector('[data-available-patchsets]');
				const patchsetLoadOrderPanel = configurator.querySelector('[data-patchset-load-order-panel]');
				const patchsetLoadOrderList = patchsetLoadOrderPanel.querySelector('[data-patchset-load-order]');
				const patchsetLoadOrderEntryTemplate = patchsetLoadOrderPanel.querySelector('[data-patchset-load-order-entry-template]');
				const generatePackageButton = configurator.querySelector('[data-generate-package-button]');
				const exportLoadOrderButton = configurator.querySelector('[data-export-load-order-button]');
				const importLoadOrderButton = configurator.querySelector('[data-import-load-order-button]');
				const cancelConfiguratorButton = configurator.querySelector('[data-cancel-configurator-button]');
				const importExportZone = configurator.querySelector('[data-import-export-zone]');
				const uiScaleInput = configurator.querySelector('[data-ui-scale]');

				const handleChangeOfPatchsetLoadOrderPosition = (event, moveFocusWithPatchset) =>
				{
					let newPosition = parseInt(event.target.value);
					newPosition = newPosition >= minimumPatchsetLoadOrderPosition ? newPosition : minimumPatchsetLoadOrderPosition;

					event.target.value = newPosition;

					const repositionedPatchset = event.target.closest('[data-id]');
					let nextPatchset;
					let nextPositionIsTheSame;

					/* A binary-search could be better for this. But, n is small. */
					for (const patchset of patchsetLoadOrderList.children)
					{
						const nextPosition = parseInt(patchset.querySelector('[data-position]').value);

						if (nextPosition >= newPosition && patchset !== repositionedPatchset)
						{
							nextPositionIsTheSame = nextPosition == newPosition;
							nextPatchset = patchset;

							break;
						}
					}

					const previousProceedingPatchset = repositionedPatchset.nextElementSibling;
					patchsetLoadOrderList.insertBefore(repositionedPatchset, nextPatchset);
					(moveFocusWithPatchset ? repositionedPatchset : (previousProceedingPatchset || patchsetLoadOrderList.lastElementChild)).querySelector('[data-position]').focus();

					if (nextPositionIsTheSame)
					{
						let patchset = nextPatchset;

						do
						{
							const position = patchset.querySelector('[data-position]');
							position.value = parseInt(position.value) + 1;
						}
						while (patchset = patchset.nextElementSibling);
					}
				};

				const handleChangeOfPatchsetLoadOrderPositionEvent = event => handleChangeOfPatchsetLoadOrderPosition(event, true);

				const handleKeyDownForPatchsetLoadOrderPosition = event =>
				{
					if (event.key === 'Enter')
					{
						handleChangeOfPatchsetLoadOrderPosition(event, event.shiftKey);
					}
				};

				const addPatchsetToLoadOrder = patchset =>
				{
					const entry = document.importNode(patchsetLoadOrderEntryTemplate.content, true).firstElementChild;
					const id = patchset[patchsetID];
					entry.dataset.id = id;
					entry.querySelector('[data-name]').innerText = patchset[patchsetName];
					entry.querySelector('[data-id]').innerText = id;
					entry.querySelector('[data-version]').innerText = patchset[patchsetVersion];
					const position = entry.querySelector('[data-position]');
					position.disabled = patchset[patchsetFixedActiveState];

					const lastPatchset = patchsetLoadOrderList.lastElementChild;
					position.value = parseInt(lastPatchset != null ? lastPatchset.querySelector('[data-position]').value : 0) + 1;

					position.addEventListener('change', handleChangeOfPatchsetLoadOrderPositionEvent);
					position.addEventListener('keydown', handleKeyDownForPatchsetLoadOrderPosition);

					return patchsetLoadOrderList.appendChild(entry);
				};

				const handleChangeOfPatchsetActiveState = event =>
				{
					const id = event.currentTarget.closest('[data-id]').dataset.id;

					if (event.currentTarget.checked)
					{
						addPatchsetToLoadOrder(availablePatchsetsByID.get(id));
					}
					else
					{
						patchsetLoadOrderList.querySelector(``[data-id = "`${id}"]``).remove();
					}
				};

				for (const patchsetID of parseLoadOrderText(configurator.dataset.initialPatchsetLoadOrder).array)
				{
					addPatchsetToLoadOrder(availablePatchsetsByID.get(patchsetID));
				}

				for (const patchset of availablePatchsetsList.children)
				{
					patchset.querySelector('[data-patchset-is-enabled]').addEventListener('change', handleChangeOfPatchsetActiveState);
				}

				const importLoadOrderText = text =>
				{
					const {array: loadOrderArray, set: loadOrderSet} = parseLoadOrderText(text);

					patchsetLoadOrderList.replaceChildren();

					for (const patchset of availablePatchsetsList.children)
					{
						patchset.querySelector('[data-patchset-is-enabled]').checked = loadOrderSet.has(patchset.dataset.id);
					}

					for (const id of loadOrderArray)
					{
						addPatchsetToLoadOrder(availablePatchsetsByID.get(id));
					}
				};

				const currentLoadOrder = () => Array.prototype.map.call(patchsetLoadOrderList.children, e => e.dataset.id);

				const sendRequestAndSetStatusMessage = (path, body, message) => {
					generatePackageButton.disabled = true;
					cancelConfiguratorButton.disabled = true;

					return sendRequest(
						path,
						body,
						response =>
						{
							configuratorHeaderStatusMessage.innerText = message;
							configuratorHeaderStatusMessageParent.hidden = false;
						}
					);
				};

				generatePackageButton.addEventListener('click', event => sendRequestAndSetStatusMessage('/generate-package', {patchsetConfiguration: {Nucleus: {UIScale: uiScaleInput.value}}, patchsetLoadOrder: currentLoadOrder().join(' ')}, 'A package is now being generated. Please return to the PowerShell script.'));
				exportLoadOrderButton.addEventListener('click', event => importExportZone.value = currentLoadOrder().join("\r\n"));
				importLoadOrderButton.addEventListener('click', event => importLoadOrderText(importExportZone.value));
				cancelConfiguratorButton.addEventListener('click', event => sendRequestAndSetStatusMessage('/cancel', {}, 'No changes have been made, nor will any be made.'));
			};

			if (document.readyState === 'loading')
			{
				document.addEventListener('DOMContentLoaded', initialiseDocument);
			}
			else
			{
				initialiseDocument();
			}
		</script>
	</head>
	<body class="document no-margin fill-container">
		<div id="viewable_body" class="viewable-body no-margin fill-container">
			<main id="configurator" class="configurator" data-configurator data-initial-patchset-load-order="$($State.LoadOrder.ByIndex -join ' ')">
				<header>
					<h1>Tiny UI Fix for The Sims 3</h1>

					<div hidden class="panel scrollable" data-header-status-message-parent>
						<div class="textual-panel">
							<span data-header-status-message></span>
						</div>
					</div>
				</header>

				<div class="configurator-contents">
					<section id="configuration" tabindex="-1">
						<header><a href="#configuration" tabindex="-1"><h2>Configuration</h2></a></header>

						<div class="panel scrollable">
							<div class="textual-panel">
								<div class="label-grid">
									<label title="This controls the scale of the game's UI, as a multiplier. A UI scale of 1 is the game's default UI scale, whereas a UI scale of 2 would result in the game's UI being twice as big as usual.&#13;&#10;If no value is provided for the UI scale, it defaults to 1.">
										<span>UI Scale</span>
										<span class="with-units">
											<input id="ui-scale" type="number" min="0.05" step="0.05" name="ui-scale" value="$($State.UIScale)" data-ui-scale>
											<span><abbr title="times">x</abbr></span>
										</span>
									</label>
								</div>
							</div>
					</section>

					<section id="available-patchsets" tabindex="-1">
						<header><a href="#available-patchsets" tabindex="-1"><h2>Available Patchsets</h2></a></header>

						<div class="panel scrollable">
							<ul class="available-patchsets-list" data-available-patchsets>
								$(
									foreach ($Patchset in $State.AvailablePatchsets)
									{
@"
								<li class="textual-panel" data-id="$($Patchset.ID)">
									<span>
										<span><h3>$($Patchset.Name)</h3></span>
										<span>$(if ($Null -ne $Patchset.RecommendationMessage) {'Recommended! '})$($Patchset.RecommendationMessage)</span>
									</span>
									<span>$($Patchset.Description)</span>
									<span>
										<span>
											<label class="checkbox">
												<span>
													<input type="checkbox" $(if ($Patchset.Active) {'checked'}) $(if ($Patchset.FixedActiveState) {'disabled'}) autocomplete="off" data-patchset-is-enabled>
													<span>Enabled?</span>
												</span>
											</label>
										</span>
										<span>ID: $($Patchset.ID)</span>
										<span>v$($Patchset.Version)</span>
									</span>
								</li>
"@
									}
								)
							</ul>
						</div>
					</section>

					<section id="patchset-load-order" tabindex="-1">
						<header><a href="#patchset-load-order" tabindex="-1"><h2>Patchset load-order</h2></a></header>

						<div class="panel scrollable" data-patchset-load-order-panel>
							<p>
								To change the order that the patchsets are loaded and applied in: change a number in any of the "Position" text-boxes, and then press enter or leave the text-box.
								<br>
								When enter is pressed, the keyboard focus will stay in the same place, to move the keyboard focus with the patchset: press shift and enter instead of only enter.
							</p>

							<template data-patchset-load-order-entry-template>
								<li class="textual-panel">
									<span>
										<span>Position</span>
										<input inputmode="numeric" data-position>
									</span>
									<span>
										<span data-name></span>
										<span>ID: <span data-id></span></span>
										<span>v<span data-version></span></span>
									</span>
								</li>
							</template>

							<ol class="patchset-load-order-list" data-patchset-load-order>
							</ol>
						</div>
					</section>

					<footer>
						<h2>Actions</h2>
						<button type="button" data-generate-package-button>Generate package</button>
						<button type="button" data-export-load-order-button>Export load-order</button>
						<button type="button" data-import-load-order-button>Import load-order</button>
						<button type="button" data-cancel-configurator-button>Cancel</button>
						<label class="import-export-zone-panel">
							<h3>Import/Export</h3>
							<textarea spellcheck="false" autocapitalize="none" autocomplete="off" data-import-export-zone></textarea>
						</label>
					</footer>
				<div>
			</main>
		</div>
	</body>
</html>
"@

