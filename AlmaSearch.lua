interfaceMngr = nil;
requestCountForm = {};
requestCountForm.Form = nil;
requestCountForm.Grid = nil;
requestCountForm.TextEdit = nil;
requestCountForm.RibbonPage = nil;
--settings.AddonRibbonName = GetSetting("AddonRibbonName");

connection = nil;

function Init()
  connection = CreateManagedDatabaseConnection();
  connection:Connect();
  interfaceMngr = GetInterfaceManager();
  --interfaceMngr:ShowMessage("Got hurrrrrrr", "Yo");
  requestCountForm.Form = interfaceMngr:CreateForm("AlmaSearch", "Script");
  
  requestCountForm.Browser = requestCountForm.Form:CreateBrowser("AlmaSearch", "AlmaSearch", "AlmaSearch");
  
  -- Hide the text label                                                                                                                                                                                                      
  requestCountForm.Browser.TextVisible = false;

  --Suppress Javascript errors                                                                                                                                                                                                
  requestCountForm.Browser.WebBrowser.ScriptErrorsSuppressed = true; 
  
  requestCountForm.RibbonPage = requestCountForm.Form:GetRibbonPage("AlmaSearch");
  requestCountForm.RibbonPage:CreateButton("AlmaSearch", GetClientImage("Search32"), "AlmaSearch", "AlmaSearch");
  requestCountForm.Form:Show();
  requestCountForm.Browser:Navigate("http://osulibrary.oregonstate.edu");
  
  connection:Dispose();
end

function AlmaSearch()
	interfaceMngr:ShowMessage("Got hurrrrrrr", "Yo");
end