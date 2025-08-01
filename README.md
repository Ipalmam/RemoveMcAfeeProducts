This scropt runs locally and can be deployed with an SCCM tool, it removes McAfee Adaptive Threat Protection first as it manage drivesr for the rest of products, then it proceeds to remove McAfee Agent as it can be removed by FrmInst.exe, 
it can be located in ¨C:\Program Files\McAfee\Agent\x86\¨, as next step removed McAfee Data loss Prevention as this app needs a token to be removed and if you have no more McAfee or Trelix license this tool removes it without it by using 
SYSTEM privileges and finally the rest of products as they are installed a regular CIM instance
