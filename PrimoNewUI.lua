-- About PrimoNewUI.lua
--
-- Author: Bill Jones III, SUNY Geneseo, IDS Project, jonesw@geneseo.edu
-- PrimoNewUI.lua provides a basic search for ISBN, ISSN, Title, and Phrase Searching for the Primo New UI interface.
-- There is a config file that is associated with this Addon that needs to be set up in order for the Addon to work.
-- Please see the ReadMe.txt file for example configuration values that you can pull from your Primo New UI URL.
--
-- IMPORTANT:  One of the following settings must be set to true in order for the Addon to work:
-- set GoToLandingPage to true for this script to automatically navigate to your instance of Primo New UI.
-- set AutoSearchISxN to true if you would like the Addon to automatically search for the ISxN.
-- set AutoSearchTitle to true if you would like the Addon to automatically search for the Title.

local settings = {};
settings.GoToLandingPage = GetSetting("GoToLandingPage");
settings.AutoSearchISxN = GetSetting("AutoSearchISxN");
settings.AutoSearchTitle = GetSetting("AutoSearchTitle");
settings.PrimoURL = GetSetting("PrimoURL");
settings.BaseURL = GetSetting("BaseURL")
settings.DatabaseName = GetSetting("DatabaseName");

local interfaceMngr = nil;
local PrimoNewUIForm = {};
PrimoNewUIForm.Form = nil;
PrimoNewUIForm.Browser = nil;
PrimoNewUIForm.RibbonPage = nil;

function Init()
    -- The line below makes this Addon work on all request types.
    if GetFieldValue("Transaction", "RequestType") ~= "" then
    interfaceMngr = GetInterfaceManager();

    -- Create browser
    PrimoNewUIForm.Form = interfaceMngr:CreateForm("PrimoNewUI", "Script");
    PrimoNewUIForm.Browser = PrimoNewUIForm.Form:CreateBrowser("PrimoNewUI", "PrimoNewUI", "PrimoNewUI");

    -- Hide the text label
    PrimoNewUIForm.Browser.TextVisible = false;

    --Suppress Javascript errors
    PrimoNewUIForm.Browser.WebBrowser.ScriptErrorsSuppressed = true;

    -- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method. We can retrieve that one and add our buttons to it.
    PrimoNewUIForm.RibbonPage = PrimoNewUIForm.Form:GetRibbonPage("PrimoNewUI");
    -- The GetClientImage("Search32") pulls in the magnifying glass icon. There are other icons that can be used.
	-- Here we are adding a new button to the ribbon
	PrimoNewUIForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", "PrimoNewUI");
	PrimoNewUIForm.RibbonPage:CreateButton("Search Title", GetClientImage("Search32"), "SearchTitle", "PrimoNewUI");
	PrimoNewUIForm.RibbonPage:CreateButton("Phrase Search", GetClientImage("Search32"), "SearchPhrase", "PrimoNewUI");
	PrimoNewUIForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "PrimoNewUI");
	
    PrimoNewUIForm.Form:Show();
    end
	if settings.GoToLandingPage then
		DefaultURL();
	elseif settings.AutoSearchISxN then
		SearchISxN();
	elseif settings.AutoSearchTitle then
		SearchTitle();
	end
end

-- InputLocation assumes that we have the following classes in place to work as expected:

-- a) available in main lib: 
-- class: "availability-status available_in_maininstitution"
                
-- b) not available: 
-- class: "availability-status unavailable_in_institution"
                
-- c) avalable online: 
-- class: "availability-status not_restricted"
                
-- d) available in other libraries: 
-- class: "availability-status available_in_institution"
                
-- e) request this item (may be loanable): 
-- class: "availability-status unavailable_in_maininstitution_more"
                
-- f) check holdings (on hold): 
-- class: "availability-status check_holdings_in_institution"

function InputLocation()
    local element =nil;
	local cElements = PrimoNewUIForm.Browser.WebBrowser.Document:GetElementsByTagName("prm-search-result-availability-line");
	if cElements == nil then
		return false;
	end
	--interfaceMngr:ShowMessage("cElements.Count=" .. cElements.Count, "debug");
	
	for i=0, cElements.Count - 1 do
        local element1 = PrimoNewUIForm.Browser:GetElementByCollectionIndex(cElements, i);
        -- only return the first item
        if i == 0 then
            local subElements = element1:GetElementsByTagName("span");

            if subElements == nil then
		        break;
	        end
            --interfaceMngr:ShowMessage("subElements.Count=" .. subElements.Count, "debug");

            local libraryName = "";
            local collectionName = "";
            local location = "";
            local callNumber = "";
                
            for j=0, subElements.Count - 1 do
                local subelement1 = PrimoNewUIForm.Browser:GetElementByCollectionIndex(subElements, j);
                
                -- get library name         
		        if subelement1:GetAttribute("className")=="best-location-library-code locations-link" then
                    libraryName = subelement1.InnerText;
		        end

		        -- get collection name 
		        if subelement1:GetAttribute("className")=="best-location-sub-location locations-link" then
                    collectionName = subelement1.InnerText;
                    location = FormatLocation(libraryName, collectionName);
		        end

                if subelement1:GetAttribute("className")=="availability-status not_restricted" then
                    location = "Online access";
                end

                -- set call number
                if subelement1:GetAttribute("className")=="best-location-delivery locations-link" then
                    callNumber = CleanupCallNum(subelement1.InnerText);
					SetFieldValue("Transaction", "CallNumber", callNumber);
					-- debug
                    -- interfaceMngr:ShowMessage("CallNumber has been set to: " .. callNumber, "CallNumber Info Updated for Request");
			        break;
		        end
            end

            -- set location
            if location ~= "" then
				SetFieldValue("Transaction", "Location", location);
				-- debug
                -- interfaceMngr:ShowMessage("Location has been set to: " .. location, "Location Info Updated for Request");
            end

            break;
        end
	end

    ExecuteCommand("SwitchTab", {"Detail"});
    return;
end

function FormatLocation(libraryName, collectionName)
    libraryName = TrimSpaces(libraryName);
    if libraryName == "McDowell Veterinary Library" then
        return "Vetmed " .. collectionName;
    elseif libraryName == "Guin Library-Newport" then
        return "Guin " .. collectionName;
    else
        return collectionName;
    end
end

function CleanupCallNum(callNum)
    local tmpStr1 = string.gsub(callNum, "%(", "");
    local tmpStr2 = string.gsub(tmpStr1, "%)", "");
    return TrimSpaces(tmpStr2);
end

function TrimSpaces(str)
    --print( string.format( "Leading whitespace removed: %s", str:match( "^%s*(.+)" ) ) )
    --print( string.format( "Trailing whitespace removed: %s", str:match( "(.-)%s*$" ) ) )
    --print( string.format( "Leading and trailing whitespace removed: %s", str:match( "^%s*(.-)%s*$" ) ) )
    return str:match("^%s*(.-)%s*$")
end

function DefaultURL()
		PrimoNewUIForm.Browser:Navigate(settings.PrimoURL);
end

-- This function searches for ISxN for both Loan and Article requests.
function SearchISxN()
    if GetFieldValue("Transaction", "ISSN") ~= "" then
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," .. GetFieldValue("Transaction", "ISSN") .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
	end
end

-- This function performs a quoted phrase search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchPhrase()
    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," ..  "\"" .. GetFieldValue("Transaction", "LoanTitle")  .. "\""  .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," ..  "\"" .. GetFieldValue("Transaction", "PhotoJournalTitle")  .. "\""  .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
	end
end

-- This function performs a standard search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchTitle()
    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," ..  GetFieldValue("Transaction", "LoanTitle") .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," .. GetFieldValue("Transaction", "PhotoJournalTitle") .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
	end
end