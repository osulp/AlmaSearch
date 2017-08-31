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
local libraryurl = settings.localurl;
local DatabaseName = "OSU";
local CitationVisibility = true;
ExLibrisForm.Form = nil;
ExLibrisForm.Browser = nil;
ExLibrisForm.RibbonPage = nil;

ExLibrisForm.ReqLoanTitle = nil;
ExLibrisForm.ReqLoanAuthor = nil;
ExLibrisForm.ReqLoanPublisher = nil;
ExLibrisForm.ReqJournalTitle = nil;
ExLibrisForm.ReqArticleTitle = nil;
ExLibrisForm.ReqArticleAuthor = nil;
ExLibrisForm.ReqVol = nil;
ExLibrisForm.ReqIssue = nil;
ExLibrisForm.ReqMonth = nil;
ExLibrisForm.ReqYear = nil;
ExLibrisForm.ReqPages = nil;


function Init()

		--if GetFieldValue("Transaction", "RequestType") == "Loan" then
			interfaceMngr = GetInterfaceManager();
			
			-- Create browser
			ExLibrisForm.Form = interfaceMngr:CreateForm(settings.AddonRibbonName, "Script");
            --ExLibrisForm.RequestStatus = ExLibrisForm.Form:CreateListBox("Details", "Details"):AddItem("test");	
            
            if GetFieldValue("Transaction", "RequestType") == "Loan" then
                ExLibrisForm.ReqLoanTitle = ExLibrisForm.Form:CreateTextEdit("LoanTitle", "Loan Title");
                ExLibrisForm.ReqLoanTitle.Value = GetFieldValue("Transaction", "LoanTitle");
                ExLibrisForm.ReqLoanTitle.ReadOnly = true;
            
                ExLibrisForm.ReqLoanAuthor = ExLibrisForm.Form:CreateTextEdit("LoanAuthor", "Loan Author");
                ExLibrisForm.ReqLoanAuthor.Value =  GetFieldValue ("Transaction", "LoanAuthor");
                ExLibrisForm.ReqLoanAuthor.ReadOnly = true;
            
                ExLibrisForm.ReqLoanPublisher = ExLibrisForm.Form:CreateTextEdit("LoanPublisher", "Loan Publisher");
                ExLibrisForm.ReqLoanPublisher.Value = GetFieldValue ("Transaction", "LoanPublisher");
                ExLibrisForm.ReqLoanPublisher.ReadOnly = true;
            
            else
                ExLibrisForm.ReqJournalTitle = ExLibrisForm.Form:CreateTextEdit("JuornalTitle", "Journal Title");
                ExLibrisForm.ReqJournalTitle.Value = GetFieldValue("Transaction", "PhotoJournalTitle");
                ExLibrisForm.ReqJournalTitle.ReadOnly = true;
            
                ExLibrisForm.ReqArticleAuthor = ExLibrisForm.Form:CreateTextEdit("ArticleAuthor", "Article Author");
                ExLibrisForm.ReqArticleAuthor.Value = GetFieldValue("Transaction", "PhotoArticleAuthor");
                ExLibrisForm.ReqArticleAuthor.ReadOnly = true;

                ExLibrisForm.ReqArticleTitle = ExLibrisForm.Form:CreateTextEdit("ArticleTitle", "Article Title");
                ExLibrisForm.ReqArticleTitle.Value = GetFieldValue("Transaction", "PhotoArticleTitle");
                ExLibrisForm.ReqArticleTitle.ReadOnly = true;
            
                ExLibrisForm.ReqVol = ExLibrisForm.Form:CreateTextEdit("Volume", "Volume/Issue");
                ExLibrisForm.ReqVol.Value = GetFieldValue ("Transaction", "PhotoJournalVolume");
                ExLibrisForm.ReqVol.ReadOnly = true;

                ExLibrisForm.ReqIssue = ExLibrisForm.Form:CreateTextEdit("Issue", "Issue");
                ExLibrisForm.ReqIssue.Value = GetFieldValue ("Transaction", "PhotoJournalIssue") ;
                ExLibrisForm.ReqIssue.LabelVisible = false;
                ExLibrisForm.ReqIssue.ReadOnly = true;
            
                ExLibrisForm.ReqMonth = ExLibrisForm.Form:CreateTextEdit("Month", "Month/Year/Pages");
                ExLibrisForm.ReqMonth.Value = GetFieldValue ("Transaction", "PhotoJournalMonth");
                ExLibrisForm.ReqMonth.ReadOnly = true;

                ExLibrisForm.ReqYear = ExLibrisForm.Form:CreateTextEdit("Year", "Year");
                ExLibrisForm.ReqYear.Value = GetFieldValue ("Transaction", "PhotoJournalYear");
                ExLibrisForm.ReqYear.LabelVisible = false;
                ExLibrisForm.ReqYear.ReadOnly = true;

                ExLibrisForm.ReqPages = ExLibrisForm.Form:CreateTextEdit("Pages", "Pages");
                ExLibrisForm.ReqPages.Value = GetFieldValue ("Transaction", "PhotoJournalInclusivePages") ;
                ExLibrisForm.ReqPages.LabelVisible = false;
                ExLibrisForm.ReqPages.ReadOnly = true;
            
            end


            --ExLibrisForm.RequestStatus.LabelVisible = false;
            

            ExLibrisForm.Browser = ExLibrisForm.Form:CreateBrowser("ExLibris", "ExLibris", "ExLibris");

		    --ExLibrisForm.RequestStatusBox.TextVisible = false;
			-- Hide the text label
			ExLibrisForm.Browser.TextVisible = false;
			
			--Suppress Javascript errors
			ExLibrisForm.Browser.WebBrowser.ScriptErrorsSuppressed = true;
			
			-- Since we didn't create a ribbon explicitly before creating our browser, it will have created one using the name we passed the CreateBrowser method.  We can retrieve that one and add our buttons to it.
			ExLibrisForm.RibbonPage = ExLibrisForm.Form:GetRibbonPage("ExLibris");
		    ExLibrisForm.RibbonPage:CreateButton("Search ISxN", GetClientImage("Search32"), "SearchISxN", settings.AddonRibbonName);
			ExLibrisForm.RibbonPage:CreateButton("Search Book/Article Title", GetClientImage("Search32"), "SearchTitle", settings.AddonRibbonName);
            ExLibrisForm.RibbonPage:CreateButton("Search Book/Journal Title", GetClientImage("Search32"), "SearchJournalTitle", settings.AddonRibbonName);
            ExLibrisForm.RibbonPage:CreateButton("Show/Hide Details", GetClientImage("DocumentDelivery32"), "ShowHideDetails", settings.AddonRibbonName);

			ExLibrisForm.RibbonPage:CreateButton("Input Location/ Call Number", GetClientImage("Borrowing32"), "InputLocation", "Location Info");

            --ExLibrisForm.RibbonPage:CreateForm("Details","Details");
            --ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-default.xml");
            if GetFieldValue("Transaction", "RequestType") == "Loan" then
                ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-loan-default.xml");
            else
                ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-article-default.xml");
            end    

			ExLibrisForm.Form:Show();
            
			if settings.autoSearch then
                --interfaceMngr:ShowMessage("issn=<" .. GetFieldValue("Transaction", "ISSN") ..">", "debug");

			    if settings.StartwithISxN and GetFieldValue("Transaction", "ISSN") ~= "" then
                   --interfaceMngr:ShowMessage("issn=<" .. GetFieldValue("Transaction", "ISSN") ..">", "debug");
				   --ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchISxN", false);
                   SearchISxN();
			    else
                   --ExLibrisForm.Browser:RegisterPageHandler("formExists", "searchForm", "SearchJournalTitle", false);
                   SearchJournalTitle();
				end
				    
			end
	          
end



function SearchISxN()
	local issn = nil;
	local issn_tmp = nil;
	local sep = nil;
	local fields = nil;
    local found = false;
    
    if GetFieldValue("Transaction", "ISSN") ~= "" then
        
        issn = GetFieldValue("Transaction", "ISSN");
        issn = CleanIssn(issn);
        --interfaceMngr:ShowMessage("issn=<" .. issn ..">", "debug");

        --ExLibrisForm.Browser:SetFormValue("searchForm","search_field",issn);
     	ExLibrisForm.Browser:Navigate(libraryurl .. "/primo-explore/search?query=any,contains," .. issn .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. DatabaseName .. "&lang=en_US&offset=0");

	else
       interfaceMngr:ShowMessage("ISxN is not available from request form", "Insufficient Information");
	end
       --ExLibrisForm.Browser:SetFormValue("searchForm","scp.scps", settings.DefaultScope);
       --ExLibrisForm.Browser:ClickObject("goButton");

	end

function CleanIssn(issn)
    local clean = "";

    clean = RemoveSep("%(", issn);
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

function SearchTitle()
	local Articletitle = nil;
	local Loantitle = nil;

    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		if string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1) ~=nil then
			Loantitle = string.sub(GetFieldValue ("Transaction", "LoanTitle"),1, string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1)-1);
		else
			Loantitle = GetFieldValue ("Transaction", "LoanTitle");
		end
		ExLibrisForm.Browser:Navigate(libraryurl .. "/primo-explore/search?query=any,contains," ..  Loantitle .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. DatabaseName .. "&lang=en_US&offset=0");
		--ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Loantitle);
	else
		if string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)~=nil then
			 Articletitle = string.sub(GetFieldValue ("Transaction", "PhotoArticleTitle"),1, string.find(GetFieldValue ("Transaction", "PhotoArticleTitle"),"/",1)-1);
		else
			 Articletitle = GetFieldValue ("Transaction", "PhotoArticleTitle");
		end
		ExLibrisForm.Browser:Navigate(libraryurl .. "/primo-explore/search?query=any,contains," ..  Articletitle .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. DatabaseName .. "&lang=en_US&offset=0");
		--ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Articletitle);
	end
    
	--ExLibrisForm.Browser:ClickObject("goButton");

end

function SearchJournalTitle()
	local Articletitle = nil;
	local Loantitle = nil;

    --interfaceMngr:ShowMessage("GetFieldValue:" .. GetFieldValue ("Transaction", "PhotoJournalTitle"), "Debug");

    if GetFieldValue("Transaction", "RequestType") == "Loan" then  
		if string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1) ~=nil then
			Loantitle = string.sub(GetFieldValue ("Transaction", "LoanTitle"),1, string.find(GetFieldValue ("Transaction", "LoanTitle"),"/",1)-1);
		else
			Loantitle = GetFieldValue ("Transaction", "LoanTitle");
		end
		
		--ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Loantitle);
        ExLibrisForm.Browser:Navigate(libraryurl .. "/primo-explore/search?query=any,contains," ..  Loantitle .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. DatabaseName .. "&lang=en_US&offset=0");
	else
		if string.find(GetFieldValue ("Transaction", "PhotoJournalTitle"),"/",1)~=nil then
			 Articletitle = string.sub(GetFieldValue ("Transaction", "PhotoJournalTitle"),1, string.find(GetFieldValue ("Transaction", "PhotoJournalTitle"),"/",1)-1);
		else
			 Articletitle = GetFieldValue ("Transaction", "PhotoJournalTitle");
		end
		
		--ExLibrisForm.Browser:SetFormValue("searchForm","search_field", Articletitle);
        ExLibrisForm.Browser:Navigate(libraryurl .. "/primo-explore/search?query=any,contains," ..  Articletitle .. "&tab=default_tab&search_scope=osu_alma&sortby=rank&vid=" .. DatabaseName .. "&lang=en_US&offset=0");
	end
    
	--ExLibrisForm.Browser:ClickObject("goButton");
    
end

function ShowHideDetails()
    if CitationVisibility == true then
        CitationVisibility = false;
        ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-hidden-details.xml");
    else
        CitationVisibility = true;
        if GetFieldValue("Transaction", "RequestType") == "Loan" then
            ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-loan-default.xml");
        else
            ExLibrisForm.Form:LoadLayout(AddonInfo.Directory .. "\\layout-article-default.xml");
        end    
    end
    ExLibrisForm.Form:Show();

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
	local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("prm-search-result-availability-line");
	if cElements == nil then
		return false;
	end
	--interfaceMngr:ShowMessage("cElements.Count=" .. cElements.Count, "debug");
	
	for i=0, cElements.Count - 1 do
        local element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
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
                local subelement1 = ExLibrisForm.Browser:GetElementByCollectionIndex(subElements, j);
                
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
                    if settings.Popup then
                        interfaceMngr:ShowMessage("CallNumber has been set to: " .. callNumber, "CallNumber Info Updated for Request");
                    end
			        break;
		        end
            end

            -- set location
            if location ~= "" then
                SetFieldValue("Transaction", "Location", location);
                if settings.Popup then
                    interfaceMngr:ShowMessage("Location has been set to: " .. location, "Location Info Updated for Request");
                end
            end

            break;
        end
	end

	ExecuteCommand("SwitchTab", {"Detail"});
end

function IsSpanClassNameInElement(element,classname)
 -- the line below creates an array of elements that are of <span> type
    local cElements = element:GetElementsByTagName("span");

    -- if the array is empty, the function ends
    if cElements == nil then
	    return false;
    end

    local found = false;
    for i=0, cElements.Count - 1 do	        
	    element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);

        if element1:GetAttribute("className")==classname then
            found = true;
            break;
        end
    end
    return found;
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

function StringContainsOnlineAccess(str)
    if string.find(str, "Online access") then
        return true;
    else
        return false;
    end
end

function GetSourceType()
    local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName("em");
    local content = "";
    for i=0, cElements.Count - 1 do
	    element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
			    
	    if element1.ParentNode ~= nil then
		    if (element1:GetAttribute("className")=="EXLResultStatusMaybeAvailable") or (element1:GetAttribute("className")=="EXLResultStatusAvailable") then
                content = TrimSpaces(element1.InnerText);
                break
		    end
	    end -- for if element1.ParentNode
    end  -- for loop
    --interfaceMngr:ShowMessage("sourcetype=<" .. content .. ">", "debug");
    return content;
end



function IsClassNameFoundInElements(element,className)
    

 -- the line below creates an array of elements that are of <span> type
    local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName(element);

    -- if the array is empty, the function ends
    if cElements == nil then
	    return false;
    end

    local found = false;
    for i=0, cElements.Count - 1 do	        
	    element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);
        parent = ExLibrisForm.Browser:GetParentElement(element1);

	    if element1.ParentNode ~= nil and parent:GetAttribute("id") == "RTADivTitle_0" then
		    if element1:GetAttribute("className")==className then
                
                --interfaceMngr:ShowMessage("element1.id:<" .. element1:GetAttribute("id")..">", "Debug");

                
			    found = true						
			    break
		    end
	    end
    end
    return found;
end

function GetInnerContentFromClass(element, className)


    -- the line below creates an array of elements that are of <span> type
    local cElements = ExLibrisForm.Browser.WebBrowser.Document:GetElementsByTagName(element);

    -- if the array is empty, the function ends
    if cElements == nil then
	    return "";
    end

    local content = "";

    -- the number of items in the array is counted	
    for i=0, cElements.Count - 1 do
	    -- the items in the array are indexed and stored in the variable "element1"
	    element1 = ExLibrisForm.Browser:GetElementByCollectionIndex(cElements, i);

		parent = ExLibrisForm.Browser:GetParentElement(element1);
        --interfaceMngr:ShowMessage("parent element:<" .. parent:GetAttribute("id") ..">", "Debug");
        	    
	    -- if <span> elements exist in the array, the function continues   
	    if element1.ParentNode ~= nil and parent:GetAttribute("id") == "RTADivTitle_0" then
		    -- the line below looks through the <span> elements for the className
		    if element1:GetAttribute("className")==className then
                
			    -- if the className "EXLAvailabilityCollectionName" exists, it is set to a local variable by getting the inner text
                content = element1.InnerText;
                break
		    end
	    end -- for if element1.ParentNode
    end  -- for loop
    return content;
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