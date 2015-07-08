interfaceMngr = nil;
requestCountForm = {};
requestCountForm.Form = nil;
requestCountForm.Grid = nil;
requestCountForm.TextEdit = nil;
requestCountForm.RibbonPage = nil;
connection = nil;

function Init()
  connection = CreateManagedDatabaseConnection();
  connection:Connect();
  interfaceMngr = GetInterfaceManager();
  interfaceMngr:ShowMessage("Got hurrrrrrr", "Yo");
  requestCountForm.Form = interfaceMngr:CreateForm("Search", "Script");
  requestCountForm.RibbonPage = requestCountForm.Form:CreateRibbonPage("AlmaSearch");
  requestCountForm.RibbonPage:CreateButton("AlmaSearch", GetClientImage("Search32"), "AlmaSearch", "AlmaSearch");
  requestCountForm.Form:Show();
  connection:Dispose();
end

function AlmaSearch()
	interfaceMngr:ShowMessage("Got hurrrrrrr", "Yo");
end