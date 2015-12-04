-- About AlmaSearch.lua
--
-- Based on the addon ExLibris_Alma_Primo addon by Bill Jones III, SUNY Geneseo, IDS Project, jonesw@geneseo.edu
-- ExLibris_Alma_Primo.lua does an ISxN or Title search for loans and articles on a Library's ALMA / Primo instance.
-- This Addon may be set to default search on either ISxN or Title setting the value "StartwithISxN" to TRUE in the Addon Configuration under Manage Addons
-- autoSearch (boolean) determines whether the search is performed automatically when a request is opened or not.
-- For your own library catalog, go to the 'Basic Search' page and copy the short version of the URL to enter in for the value of "libraryurl" in the Addon Configuration under Manage Addons
-- You are able to name the Addon Tab!  In the the Addon Configuration under Manage Addons, change the "AddonRibbonName" value to reflect your catalog (example: Primo) (example: Alma)
-- set autoSearch to true for this script to automatically run the search when the request is opened.
-- 
-- IMPORTING CALL NUMBER AND LOCATION INFORMATION INTO THE DETAILS TAB:
-- In order to input the Call Number and Location information into the request, click on the "Locations" tab of the requested item within the catalog.
-- Once the Call Number and Location information has populated on the page, click on the "Input Location/Call Number" button on the top ILLiad Client ribbon.
-- You will automatically be redirected to the Details tab.
-- Be sure to click Save for the item in the "Details" tab of the request.


local settings = {};
settings.localurl = GetSetting("localurl");
settings.autoSearch = GetSetting("AutoSearch");
settings.Popup = GetSetting("Popup");
settings.AddonRibbonName = GetSetting("AddonRibbonName");
settings.StartwithISxN = GetSetting("StartwithISxN");
settings.DefaultScope = GetSetting("DefaultScope");
local interfaceMngr = nil;
local ExLibrisForm = {};
local libraryurl = settings.localurl
ExLibrisForm.Form = nil;
ExLibrisForm.Browser = nil;
ExLibrisForm.RibbonPage = nil;



function Init()

		--if GetFieldValue("Transaction", "RequestType") == "Loan" then
			interfaceMngr = GetInterfaceManager();
			
			-- Create browser
			ExLibrisForm.Form = interfaceMngr:CreateForm(settings.AddonRibbonName, "Script");
			ExLibrisForm.Browser = ExLibrisForm.Form:CreateBrowser("ExLibris", "ExLibris", "ExLibris");
			
			-- Hide the text label
			ExLibrisForm.Browser.TextVisible = false;
			
			--Suppress Javascript errors
			ExLibrisForm.Browser.WebBrowser.ScriptErrorsSuppressed = true;
			
			-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
			ExLibrisForm.RibbonPage = ExLibrisForm.Form:GetRibbonPage("ExLibris");
		    ExLibrisForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", settings.AddonRibbonName);
			ExLibrisForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", settings.AddonRibbonName);
			ExLibrisForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "Location Info");
			
			ExLibrisForm.Form:Show();
            
			if settings.autoSearch then
			    if settings.StartwithISxN and GetFieldValue("Transaction", "ISSN") ~= "" then
				   ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchISxN", false);
			    else

                   ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchTitle", false);
				end
				ExLibrisForm.Browser:Navigate(libraryurl);
                
			end
	          
end



function SearchISxN()
	local issn = nil;
	local issn_tmp = nil;
	local sep = nil;
	local fields = nil;
    local found = false;
    
    if GetFieldValue("Transaction", "ISSN") ~= "" then
        sep = "%(";
		fields = {};
        issn = GetFieldValue("Transaction", "ISSN");
		issn:gsub("([^"..sep.."]*)"..sep, function(c) table.insert(fields, c) end);
        
        --interfaceMngr:ShowMessage(fields.Count, "debug");
        
        for i,v in ipairs(fields) do 
            ExLibrisForm.Browser:SetFormValue("searchForm","search_field",v);
            found = true;
        end
        if found == false then
            ExLibrisForm.Browser:SetFormValue("searchForm","search_field",issn);
        end

	else
       interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
	end
       ExLibrisForm.Browser:SetFormValue("searchForm","scp.scps", settings.DefaultScope);
       ExLibrisForm.Browser:ClickObject("goButton");

	end

function SearchTitle()
	local Articletitle = nil;
	local Loantitle = nil;

    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		if string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1) ~=nil then
			Loantitle = string.sub(GetFieldValue ("Transaction", "LoanTitle"),1, string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1)-1);
		else
			Loantitle = GetFieldValue ("Transaction", "LoanTitle");
		end
		
		ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Loantitle);
	else
		if string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)~=nil then
			 Articletitle = string.sub(GetFieldValue ("Transaction", "PhotoArticleTitle"),1, string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)-1);
		else
			 Articletitle = GetFieldValue ("Transaction", "PhotoArticleTitle");
		end
		
		ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Articletitle);
	end
    
	ExLibrisForm.Browser:ClickObject("goButton");
    
end


function InputLocation()
	local element =nil;

	if ExLibrisForm.Browser:GetElementInFrame(nil,"locationsTabForm")~= nil then
		--local LocationValue = ExLibrisForm.Browser:GetElementInFrame(nil, "EXLLocationInfo");
		--if LocationValue==nil then
			local bElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("cite");
			if bElements == nil then
				return false;
			end

			for i=0, bElements.Count - 1 do
				 element = ExLibrisForm.Browser:GetElementByCollectionIndex(bElements, i);

				if element ~= nil then
						if string.find(element.InnerText, [[(]], 1, true) ~= nil then 
							SetFieldValue("Transaction", "CallNumber", element.InnerText);
							if settings.Popup == true then
							interfaceMngr:ShowMessage("Request Call Number Field has been set to:" .. element.InnerText, "Call Number Updated for Request");
							end
							break
						end

				end
			end -- for loop
	end
	
    if ExLibrisForm.Browser:GetElementInFrame(nil,"locationsTabForm")~= nil then
			local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("div");
			if cElements == nil then
				return false;
			end
				
			for i=0, cElements.Count - 1 do
				
				local element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
			    
				if element1.ParentNode ~= nil then
					if element1:GetAttribute("className")=="EXLLocationListContainer" then
					    local dElement = string.sub(element1.InnerText, 1, string.find(element1.InnerText,element.InnerText,1)-2);
			            SetFieldValue("Transaction", "Location", dElement);
						if settings.Popup == true then
						interfaceMngr:ShowMessage("Location has been set to: " .. dElement, "Location Info Updated for Request");
						end
						break
					end
				end
			end
	end

    --if ExLibrisForm.Browser:GetElementInFrame(nil,"exlidResult0-TabContent")~= nil then
    if ExLibrisForm.Browser:GetElementInFrame(em,"RTADivTitle_0")~= nil then
	    -- the line below creates an array of elements that are of <span> type
        local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("span");
        -- if the array is empty, the function ends
        if cElements == nil then
	        return false;
        end
        -- the number of items in the array is counted	
        for i=0, cElements.Count - 1 do
	        -- the items in the array are indexed and stored in the variable "element1"
	        element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
			    
	        -- if <span> elements exist in the array, the function continues   
	        if element1.ParentNode ~= nil then
		        -- the line below looks through the <span> elements for the className
		        if element1:GetAttribute("className")=="EXLAvailabilityCollectionName" then
			        -- if the className "EXLAvailabilityCollectionName" exists, it is set to a local variable by getting the inner text
			        local dElement = element1.InnerText;
			        -- Here the Location field is set to the value of the InnerText of the dElement
			        SetFieldValue("Transaction", "Location", dElement);
			        -- if the user has selected to receive popups when importing Call#, they will receive a popup
			        if settings.Popup then
			            interfaceMngr:ShowMessage("Location has been set to: " .. dElement, "Collection Info Updated for Request");
			        end  -- for if PopUp						
			        break  -- stops the loop once the value is found
		        end  -- for if GetAttribute
	        end -- for if element1.ParentNode
        end  -- for loop
    end -- for if GetElementInFrame

    --if ExLibrisForm.Browser:GetElementInFrame(nil,"exlidResult0-TabContent")~= nil then
    if ExLibrisForm.Browser:GetElementInFrame(em,"RTADivTitle_0")~= nil then
	    -- the line below creates an array of elements that are of <span> type
        local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("span");
        -- if the array is empty, the function ends
        if cElements == nil then
	        return false;
        end
        -- the number of items in the array is counted	
        for i=0, cElements.Count - 1 do
	        -- the items in the array are indexed and stored in the variable "element1"
	        element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
			    
	        -- if <span> elements exist in the array, the function continues   
	        if element1.ParentNode ~= nil then
		        -- the line below looks through the <span> elements for the className
		        if element1:GetAttribute("className")=="EXLAvailabilityCallNumber" then
			        -- if the className "EXLAvailabilityCollectionName" exists, it is set to a local variable by getting the inner text
			        local dElement = element1.InnerText;
                    local tmpStr1 = string.gsub(dElement, "%(", "");
                    local tmpStr2 = string.gsub(tmpStr1, "%)", "");

			        -- Here the Location field is set to the value of the InnerText of the dElement
			        SetFieldValue("Transaction", "CallNumber", tmpStr2);
			        
                    -- if the user has selected to receive popups when importing Call#, they will receive a popup
			        if settings.Popup then
			            interfaceMngr:ShowMessage("CallNumber has been set to: " .. tmpStr2, "CallNumber Info Updated for Request");
			        end  -- for if PopUp						
			        break  -- stops the loop once the value is found
		        end  -- for if GetAttribute
	        end -- for if element1.ParentNode
        end  -- for loop
    end -- for if GetElementInFrame

	ExecuteCommand("SwitchTab", {"Detail"});
end