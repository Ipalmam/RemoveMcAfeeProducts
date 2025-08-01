RemoveMcAfeeProductsV1.0.ps1 runs locally and can be deployed with an SCCM tool, it removes McAfee Adaptive Threat Protection first as it manage drivesr for the rest of products, then it proceeds to remove McAfee Agent as it can be removed by FrmInst.exe, 
it can be located in ¨C:\Program Files\McAfee\Agent\x86\¨, as next step removed McAfee Data loss Prevention as this app needs a token to be removed and if you have no more McAfee or Trelix license this tool removes it without it by using 
SYSTEM privileges and finally the rest of products as they are installed a regular CIM instance


RemovMcAfeeProductsRemotellyInBulk.ps1 can be ran on a host that can reach devices with mcafee products installed, and other diference is this script uses PsExec64 to remove McAfee DLP instead a sheduled task with system permissions, it validates if host has been found on DNS records and if so it check if device is available, if this condition is fulfilled it will proceed to verify if mcafee products are installed and remove then if so
