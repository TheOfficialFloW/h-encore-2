# h-encore²

*h-encore²*, where *h* stands for hacks and homebrews, is the fourth public jailbreak for the *PS Vita™* which supports the newest firmwares 3.65-3.71. It allows you to make kernel- and user-modifications, change the clock speed, install plugins, run homebrews and much more.

## Requirements

- Your device must be on firmware 3.65-3.71. If you're on a lower firmware, please decide carefully to what firmware you want to update, then search for a trustable guide on [/r/vitahacks](https://www.reddit.com/r/vitahacks/).
- If your device is a phat OLED model, you need a Memory Card in order to install. There's no need for a Memory Card on Slim/PS TV models, since they already provide an Internal Storage. Make sure you have got at least `270 MB` of free space.
- Your device must be linked to any PSN account (it doesn't need to be activated though). If it is not, then you must restore default settings in order to sign in.

## Installation

1. Download [h-encore²](https://github.com/TheOfficialFloW/h-encore-2/releases/download/v1.0/h-encore-2.zip) and extract it on your computer.

2. Download and install [qcma](https://codestation.github.io/qcma/), [psvimgtools](https://github.com/yifanlu/psvimgtools) and [pkg2zip](https://github.com/mmozeiko/pkg2zip) (check the releases section for the binaries).  
   If you don't know where to put psvimgtools and pkg2zip binaries, just put them in the `h-encore-2` folder.

3. Download the vulnerable DRM-free demo of [bitter smile](http://ares.dl.playstation.net/cdn/JP0741/PCSG90096_00/xGMrXOkORxWRyqzLMihZPqsXAbAXLzvAdJFqtPJLAZTgOcqJobxQAhLNbgiFydVlcmVOrpZKklOYxizQCRpiLfjeROuWivGXfwgkq.pkg) (yes, that's the user entry point).

4. Extract the demo using this command in terminal/cmd:
   ```
   pkg2zip -x PATH_OF_PKG
   ```

   This will output the files to `app/PCSG90096`.

5. Copy the contents of the output `app/PCSG90096` to the folder `h-encore-2/app/ux0_temp_game_PCSG90096_app_PCSG90096` (such that the files `eboot.bin` and `VITA_PATH.TXT` are within the same folder).

6. Copy the license file `app/PCSG90096/sce_sys/package/temp.bin` to the folder  
   `h-encore-2/license/ux0_temp_game_PCSG90096_license_app_PCSG90096` and rename the just pasted file `temp.bin` to ` 6488b73b912a753a492e2714e9b38bc7.rif`. Be careful with the file extension, it should not be `.rif.bin`. Again, this file should be in the same folder as `VITA_PATH.TXT`.

7. Start qcma and within the qcma settings set the option `Use this version for updates` to `FW 0.00 (Always up-to-date)` to spoof the System Software check.

8. Launch Content Manager on your PS Vita and connect it to your computer, where you then need to select `PC -> PS Vita System`, and after that you select `Applications`. If you see an error message about System Software, you should simply reboot your device to solve it (if this doesn't solve, then put your device into airplane mode and reboot). If this does still not work, then alternatively set DNS to `212.47.229.76` to block updates.
   This should create a folder at `PS Vita/APP/xxxxxxxxxxxxxxxx` on your computer (see qcma settings where this folder is), where the folder `xxxxxxxxxxxxxxxx` represents the AID (account ID that is 16 characters long) that you need to insert [here](http://cma.henkaku.xyz/). If the AID is valid, it will yield a key that you can now use to encrypt the demo.

9. Change directory to the `h-encore-2` folder in terminal/cmd and use the key to encrypt all folders using (make sure you don't confuse the key with the AID, the key is 64 characters long!):
   ```
   psvimg-create -n app -K YOUR_KEY app PCSG90096/app
   psvimg-create -n appmeta -K YOUR_KEY appmeta PCSG90096/appmeta
   psvimg-create -n license -K YOUR_KEY license PCSG90096/license
   psvimg-create -n savedata -K YOUR_KEY savedata PCSG90096/savedata
   ```

    The folder `h-encore-2/PCSG90096` should then contain `sce_sys` and all 4 folders from above, and within these folders you should find files called `X.psvimg` and `X.psvmd`, where `X` has the same name as the folder. Backup this folder, since if everything has been done correctly, you don't need to redo all the steps to install it onto another device with the same PSN account.

10. Copy the folder `h-encore-2/PCSG90096` to `PS Vita/APP/xxxxxxxxxxxxxxxx/PCSG90096` and then select `Refresh database` in qcma.

11. The *h-encore²* bubble with a size of around `243 MB` should now appear in the Content Manager and that's what you finally need to transfer to your PS Vita. If the size does not match or you get the error `C2-12858-4`, then it's because you did not do it correctly! Please re-read the instructions more carefully then. If you get the error `You can only copy applications that your account is the owner of`, then it's because you have used an AID that is not of your account, go back to step 8.

12. Launch *h-encore²* to exploit your device (if a message about trophies appears, simply click yes).
    The screen should first flash white, then purple, and finally open a menu called *h-encore bootstrap menu* where you can download [VitaShell](https://github.com/TheOfficialFloW/VitaShell) and install [HENkaku](https://github.com/henkaku).
    If it prompts the error `Cannot start this application. C0-11136-2`, then it's because you did not do step 6. correctly.

13. Enjoy. Note that you have to relaunch the exploit everytime you reboot or shutdown your device. Of course if you only put your device into standby mode, you don't need to relaunch.

## FAQ

### Exploit

- "When I launch *h-encore²*, it flashes white quickly and then crashes." - The success rate of the exploit is around 25%. You need to attempt it a few times. Note that trimming the bittersmile application seems to make the exploit less reliable.
- "I get a C2-12828-1 error when launching *h-encore²*" - This does sometimes (but very rarely) happen. Just retry the exploit.
- "When I launch *h-encore²*, it launches the bitter smile demo instead." - Your savedata is either corrupted or not installed correctly, please follow the installation guide above to reinstall it.
- "I have installed a bad plugin and launching *h-encore²* doesn't work anymore, what should I do?" - You can either reset taiHEN config.txt or skip plugins loading by holding the L trigger while exiting the *h-encore bootstrap menu*.

### HENkaku Settings

- "I don't see all folders in VitaShell." - Launch the Settings application and select `HENkaku Settings`, then select `Enable unsafe homebrews`. This will grant you full permission in VitaShell.
- "I can't find the HENkaku Settings." - Launch the exploit and reset taiHEN config.txt and reinstall HENkaku.

### enso/permanent hack

- "Can I install enso on 3.67-3.71?" - Not on this firmware, but you can downgrade to firmware 3.65 using [modoru](https://github.com/TheOfficialFloW/modoru) and then install enso.
- "Can I install enso on 3.65?" - Yes, you can use *h-encore²* to hack your device and then install the permanent hack using [this](https://github.com/TheOfficialFloW/enso/releases).

### General

- "Can I switch the PSN account after having *h-encore²* installed?" - Yes, since the demo is DRM-free it does not depend on your account.
- "Are there any risks involved in using *h-encore²*?" - No, since it does not modify the OS, but only insert temporary patches into the system.
- "Can I install it without USB connection?" - You can also connect your PS Vita with your computer using Wi-Fi (there's an option in the Content Manager).

## Donation

If you like my work and want to support future projects, you can make a donation:

- via bitcoin `361jRJtjppd2iyaAhBGjf9GUCWnunxtZ49`
- via [paypal](https://www.paypal.me/flowsupport/20)
- via [patreon](https://www.patreon.com/TheOfficialFloW)

Thank you!

## Credits

- Thanks to Freakler for finding the crash in the demo and designing the *h-encore²* icon.
- Thanks to molecule for their initial work on the PS Vita.
- Thanks to Davee and Proxima for http://cma.henkaku.xyz/.
- Thanks to yifanlu for psvimgtools.
- Thanks to codestation for qcma.
- Thanks to mmozeiko for pkg2vita.
- Thanks to the PS Vita hacking community.
- Thanks to Sony for this awesome device.
