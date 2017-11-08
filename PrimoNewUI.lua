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
PrimoNewUIForm.CitationVisibility = true;

PrimoNewUIForm.ReqLoanTitle = nil;
PrimoNewUIForm.ReqLoanAuthor = nil;
PrimoNewUIForm.ReqLoanPublisher = nil;
PrimoNewUIForm.ReqJournalTitle = nil;
PrimoNewUIForm.ReqArticleTitle = nil;
PrimoNewUIForm.ReqArticleAuthor = nil;
PrimoNewUIForm.ReqVol = nil;
PrimoNewUIForm.ReqIssue = nil;
PrimoNewUIForm.ReqMonth = nil;
PrimoNewUIForm.ReqYear = nil;
PrimoNewUIForm.ReqPages = nil;

require "Atlas.AtlasHelpers";

function Init()
    -- The line below makes this Addon work on all request types.
    if GetFieldValue("Transaction", "RequestType") ~= "" then
    interfaceMngr = GetInterfaceManager();

    -- Create Form
    PrimoNewUIForm.Form = interfaceMngr:CreateForm("PrimoNewUI", "Script");

    -- Create TextEdit elements to hold request values
    if GetFieldValue("Transaction", "RequestType") == "Loan" then
        PrimoNewUIForm.ReqLoanTitle = PrimoNewUIForm.Form:CreateTextEdit("LoanTitle", "Loan Title");
        PrimoNewUIForm.ReqLoanTitle.Value = GetFieldValue("Transaction", "LoanTitle");
        PrimoNewUIForm.ReqLoanTitle.ReadOnly = true;
    
        PrimoNewUIForm.ReqLoanAuthor = PrimoNewUIForm.Form:CreateTextEdit("LoanAuthor", "Loan Author");
        PrimoNewUIForm.ReqLoanAuthor.Value =  GetFieldValue ("Transaction", "LoanAuthor");
        PrimoNewUIForm.ReqLoanAuthor.ReadOnly = true;
    
        PrimoNewUIForm.ReqLoanPublisher = PrimoNewUIForm.Form:CreateTextEdit("LoanPublisher", "Loan Publisher");
        PrimoNewUIForm.ReqLoanPublisher.Value = GetFieldValue ("Transaction", "LoanPublisher");
        PrimoNewUIForm.ReqLoanPublisher.ReadOnly = true;
    
    else
        PrimoNewUIForm.ReqJournalTitle = PrimoNewUIForm.Form:CreateTextEdit("JuornalTitle", "Journal Title");
        PrimoNewUIForm.ReqJournalTitle.Value = GetFieldValue("Transaction", "PhotoJournalTitle");
        PrimoNewUIForm.ReqJournalTitle.ReadOnly = true;
    
        PrimoNewUIForm.ReqArticleAuthor = PrimoNewUIForm.Form:CreateTextEdit("ArticleAuthor", "Article Author");
        PrimoNewUIForm.ReqArticleAuthor.Value = GetFieldValue("Transaction", "PhotoArticleAuthor");
        PrimoNewUIForm.ReqArticleAuthor.ReadOnly = true;

        PrimoNewUIForm.ReqArticleTitle = PrimoNewUIForm.Form:CreateTextEdit("ArticleTitle", "Article Title");
        PrimoNewUIForm.ReqArticleTitle.Value = GetFieldValue("Transaction", "PhotoArticleTitle");
        PrimoNewUIForm.ReqArticleTitle.ReadOnly = true;
    
        PrimoNewUIForm.ReqVol = PrimoNewUIForm.Form:CreateTextEdit("Volume", "Volume/Issue");
        PrimoNewUIForm.ReqVol.Value = GetFieldValue ("Transaction", "PhotoJournalVolume");
        PrimoNewUIForm.ReqVol.ReadOnly = true;

        PrimoNewUIForm.ReqIssue = PrimoNewUIForm.Form:CreateTextEdit("Issue", "Issue");
        PrimoNewUIForm.ReqIssue.Value = GetFieldValue ("Transaction", "PhotoJournalIssue") ;
        PrimoNewUIForm.ReqIssue.LabelVisible = false;
        PrimoNewUIForm.ReqIssue.ReadOnly = true;
    
        PrimoNewUIForm.ReqMonth = PrimoNewUIForm.Form:CreateTextEdit("Month", "Month/Year/Pages");
        PrimoNewUIForm.ReqMonth.Value = GetFieldValue ("Transaction", "PhotoJournalMonth");
        PrimoNewUIForm.ReqMonth.ReadOnly = true;

        PrimoNewUIForm.ReqYear = PrimoNewUIForm.Form:CreateTextEdit("Year", "Year");
        PrimoNewUIForm.ReqYear.Value = GetFieldValue ("Transaction", "PhotoJournalYear");
        PrimoNewUIForm.ReqYear.LabelVisible = false;
        PrimoNewUIForm.ReqYear.ReadOnly = true;

        PrimoNewUIForm.ReqPages = PrimoNewUIForm.Form:CreateTextEdit("Pages", "Pages");
        PrimoNewUIForm.ReqPages.Value = GetFieldValue ("Transaction", "PhotoJournalInclusivePages") ;
        PrimoNewUIForm.ReqPages.LabelVisible = false;
        PrimoNewUIForm.ReqPages.ReadOnly = true;
    end

    -- Create browser
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
    PrimoNewUIForm.RibbonPage:CreateButton("Show/Hide Details", GetClientImage("DocumentDelivery32"), "ShowHideDetails", "PrimoNewUI");
    PrimoNewUIForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "PrimoNewUI");    
    
    if GetFieldValue("Transaction", "RequestType") == "Loan" then
        PrimoNewUIForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-loan-default.xml");
    else
        PrimoNewUIForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-article-default.xml");
    end

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

function ShowHideDetails()
    if PrimoNewUIForm.CitationVisibility == true then
        PrimoNewUIForm.CitationVisibility = false;
        PrimoNewUIForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-hidden-details.xml");
    else
        PrimoNewUIForm.CitationVisibility = true;
        if GetFieldValue("Transaction", "RequestType") == "Loan" then
            PrimoNewUIForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-loan-default.xml");
        else
            PrimoNewUIForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-article-default.xml");
        end    
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
        issn = GetFieldValue("Transaction", "ISSN");
        issn = CleanIssn(issn);
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," .. AtlasHelpers.UrlEncode(issn) .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
	end
end

function CleanIssn(issn)
    local clean = "";
    clean = TrimSpaces(issn);
    clean = RemoveSep("%(", clean);
    clean = RemoveSep(" ", clean);

    return clean;
end

function RemoveSep(sep, issn)
    fields = {};
    local out = "";
    out = issn:gsub("([^"..sep.."]*)"..sep, function(c) table.insert(fields, c) end);

    for i,v in ipairs(fields) do 
        out = v;
    end
    
    return out;
end

-- This function performs a quoted phrase search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchPhrase()
    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," ..  "\"" .. AtlasHelpers.UrlEncode(GetFieldValue("Transaction", "LoanTitle"))  .. "\""  .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," ..  "\"" .. AtlasHelpers.UrlEncode(GetFieldValue("Transaction", "PhotoJournalTitle"))  .. "\""  .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
	end
end

-- This function performs a standard search for LoanTitle for Loan requests and PhotoJournalTitle for Article requests.
function SearchTitle()
    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," .. AtlasHelpers.UrlEncode(GetFieldValue("Transaction", "LoanTitle")) .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	elseif GetFieldValue("Transaction", "RequestType") == "Article" then  
		PrimoNewUIForm.Browser:Navigate(settings.BaseURL .. "/primo-explore/search?query=any,contains," .. AtlasHelpers.UrlEncode(GetFieldValue("Transaction", "PhotoJournalTitle")) .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. settings.DatabaseName .. "&lang=en_US&offset=0");
	else
		interfaceMngr:ShowMessage("The Title is not available from request form", "Insufficient Information");
	end
end