# Tests of the HUD

Tables of the tests, one section per unit under test: the test's name,
what holds, the breakage. The rules and the conveyor are in
`../TESTING.md`; a new unit's table goes into the file of its namespace.

## Hud.Energy

State: written, 9 tests. Fixtures `TEnergyReadingTests` and `TEnergyLevelTests` in `Tests\Hud\Tests.Hud.Energy.pas`. The reading is ticked and read; the gauge is not drawn. The level test reads `level2.json` beside the executable.

| Test | Holds | Turns red when |
|---|---|---|
| `TestNoChargeNoSlot` | at 0: no slot, no arc, no flash | the panel grows a wing before the stone |
| `TestFirstChargeOpensSlotSlowly` | the first point opens the slot over 8 ticks, not at once | the slot jumps out, or never opens all the way |
| `TestArcEasesUpToCharge` | a rise to 5 is eased in and stands on 5 | the arc jumps, or settles short |
| `TestRiseFlashesAndFades` | a rise flashes at full and is dark 14 ticks on | a rise passes unseen, or the flash stays |
| `TestFallIsShownAtOnceWithoutFlash` | from 50 to 5: the arc at 5 at once, no flash | a death's fall is played as a gain |
| `TestChargeGoneFoldsSlot` | the charge gone: the slot folds over 8 ticks, no arc | the wing stays open over nothing |
| `TestEnergyActionIsRead` | `energy` with a value: `eaEnergy`, its amount, 100 too | the action or its value is lost |
| `TestEnergyOutsideOneToHundredRaises` | no value, 0 and 101 each raise | a typo gives nothing, or runs past full |
| `TestMoonStoneGivesFive` | on screen 11 the event that waits for `s11-stone` gives 5 and opens the door | the stone gives nothing, or gives it apart from the taking |

Left to the eye: the disc, the halo, the arc and its head, the number in the disc, the breath of a full ring, the wing in the monitor's frame - all drawn. That a death gives back the charge of the screen's entry is the game's (`Game.Moon`).
