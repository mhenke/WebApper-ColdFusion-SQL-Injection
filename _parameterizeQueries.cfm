<!---
_ParameterizeQueries.cfm v1.5 (20080721)

Written by Daryl Banttari dbanttari@gmail.com
RELEASED TO THE PUBLIC DOMAIN.  But feel free to credit me with original authorship if you release it with modifications.


Purpose:

	Seek out unparamaterized queries in ColdFusion templates and, at user's option, 
	parameterize them.

Use:

	Place _ParameterizeQueries.cfm in a document directory and load.
	Template will start from its current directory and proceed to read all .cfm documents in that 
	directory, find and report all <CFQUERY>s found, and, if it looks like there's a spot that
	<CFQUERYPARAM> can be used, give you the option to parameterize the query.

	If "beRecursive" is set to True (just after these comments), it will recursively
	search all subdirectories, too.

	If "overwriteInPlace" is set to True (just after these comments), it will replace the files
	in place, and save a copy of the "before" file as ".old".  If false, changes will be saved in
	files with ".new" appended.

	To parameterize, click the "Parameterize!" button at the bottom, and all selected queries
	will be parameterized, and the resulting template saved.
	Be sure to test the changes before placing the new code into production!!!

	Templates beginning with an underscore character ("_") will be skipped.
	If working recursively, directories starting with a period (".") will be skipped.
	
	Do NOT leave this on production servers..!
	
Legal:

	Furnished without warranty of ANY KIND including merchantability
	or fitness for any particular purpose.  Use at your own exclusive risk.
	
--->

<!--- set to True to work on directories recursively --->
<CFSET beRecursive=true>
<!--- set to True to overwrite files (saving old ones as .old), False to create new ".new" files. --->
<CFSET overwriteInPlace=true>
<!--- default the checkbox to CHECKED --->
<CFSET isDefaultChecked=true>

<!--- don't edit below this line (unless you don't mind breaking stuff!) --->
<CFSET crlf = "
">
<CFIF isDefined("Attributes.CurDir")>
	<CFSET CurDir = Attributes.CurDir>
<CFELSE>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">

<html>
<head>
	<title>Queries</title>
</head>

<body>
<CFSET CurDir="#GetDirectoryFromPath(CGI.Path_Translated)#">
</CFIF>

<CFDIRECTORY Action="List" 
	Directory="#CurDir#" 
	Name="Dir" 
	Filter="*.cfm">

<FORM Action="_parameterizeQueries.cfm" Method="POST">
<CFPARAM Name="ffFixMe" default="">
<TABLE Border=1>
<CFOUTPUT>
<TR>
	<TH Colspan=2 bgColor="ffff99"><font face="arial">Files in #CurDir#:</font></TH>
</TR>
</CFOUTPUT>
<TR>
	<TH bgColor="eeeeee"><font face="arial">Name</font></TH>
	<TH bgColor="eeeeee"><font face="arial">Info</font></TH>
</TR>
<CFSET TotalLines=0>
<CFSET TotalSize=0>
<cfset sql = "">
<CFLOOP Query="Dir">
<CFIF left(Dir.Name,1) IS NOT "_">
	<CFFILE Action="Read" File="#CurDir#\#Dir.Name#" Variable="TheFile">
	<cfset theOriginalFile = theFile>
	<cfset rewrite=false>
	<CFOUTPUT>
	<TR>
		<TD><font face="arial">#Dir.Name#</font></TD>
		<TD><CFSET NumLines = ListLen(TheFile,crlf)>
			<font face="arial">#Dir.Size# bytes, #NumLines# Lines</font>
			<CFSET TotalSize = TotalSize + Dir.Size>
			<CFSET TotalLines = TotalLines + Numlines>
		</TD>
	</TR>
	</CFOUTPUT>
	<cftry>
	<CFSET curpos = findNoCase("<CFQUERY",TheFile)>
	<CFLOOP Condition="#curpos#">
		<CFSET endOfTagPos = findNoCase(">",TheFile,curpos)>
		<CFSET StartTag = mid(TheFile,curpos,endOfTagPos-curpos+1)>
		<CFOUTPUT><TR><TD></TD><TD></CFOUTPUT>
		<CFIF (StartTag CONTAINS "SQL=") or (right(StartTag,2) IS "/>")>
			<CFOUTPUT><pre>#htmlcodeformat(StartTag)#</pre></CFOUTPUT>
			<CFSET curpos = endOfTagPos-curpos+1>
		<CFELSEIF (startTag contains "cachedWithin")>
			<CFSET endTagPos = findNoCase("</CFQUERY>",TheFile,curPos)+10>
			<CFSET SQL = mid(TheFile, EndOfTagPos+1, endTagPos-EndOfTagPos-1)>
			<CFOUTPUT><pre><font color="red">#htmlcodeformat(StartTag & sql)#</font></pre></CFOUTPUT>
			<CFSET curpos = endOfTagPos>
		<CFELSE>
			<CFSET endTagPos = findNoCase("</CFQUERY>",TheFile,curPos)+10>
			<CFSET SQL = mid(TheFile, EndOfTagPos+1, endTagPos-EndOfTagPos-1)>
			<cfset queryType = getToken(trim(sql), 1)>
			<CFSET SQLHash = hash(SQL)>
			<CFIF listFind(ffFixMe,SQLHash)>
				<!--- actually fix the sql --->
				<cfset rewrite=true>
				<CFIF SQL does not contain "CFQUERYPARAM">
					<cfif queryType is "insert">
						<CFSET st = reFind("([']?##[^##]+##[']?)",SQL,1,true)>
						<CFLOOP Condition="#st.pos[1]#">
							<CFSET theParam = mid(SQL, st.pos[2], st.len[2])>
							<CFIF left(theParam,1) IS "'">
								<CFSET theParam=mid(theParam,2,len(theParam)-2)>
							</CFIF>
							<CFSET SQL=removechars(SQL,st.pos[2],st.len[2])>
							<cfif theParam contains "now()" or theParam contains "date">
								<cfset newParam = "<CFQUERYPARAM Value=""#theParam#"" cfsqltype=""CF_SQL_TIMESTAMP"">">
							<cfelse>
								<cfset newParam = "<CFQUERYPARAM Value=""#theParam#"">">
							</cfif>
							<CFSET SQL=insert(newParam,SQL,st.pos[2]-1)>
							<CFSET st = reFind("([']?##[^##]+##[']?)", SQL, st.pos[1]+len(newParam), true)>
						</CFLOOP>
					<cfelse>
						<CFSET st = reFind("=[[:space:]]*([']?##[^##]+##[']?)",SQL,1,true)>
						<CFLOOP Condition="#st.pos[1]#">
							<CFSET theParam = mid(SQL, st.pos[2], st.len[2])>
							<CFIF left(theParam,1) IS "'">
								<CFSET theParam=mid(theParam,2,len(theParam)-2)>
							</CFIF>
							<cfif theParam contains "now()" or theParam contains "date">
								<cfset newParam = "<CFQUERYPARAM Value=""#theParam#"" cfsqltype=""CF_SQL_TIMESTAMP"">">
							<cfelse>
								<cfset newParam = "<CFQUERYPARAM Value=""#theParam#"">">
							</cfif>
							<CFSET SQL=removechars(SQL,st.pos[2],st.len[2])>
							<CFSET SQL=insert(newParam, SQL, st.pos[2]-1)>
							<CFSET st = reFind("\=[[:space:]]*([']?##[^##]+##[']?)", SQL, st.pos[1]+len(newParam), true)>
						</CFLOOP>
					</cfif>
				</CFIF>
				<CFOUTPUT>
				<strong>Parameterized!</strong><br>
				<pre>#htmlcodeformat(StartTag & SQL)#</pre>
				</CFOUTPUT>
				<CFSET TheFile = removeChars(TheFile, EndOfTagPos+1, endTagPos-EndOfTagPos-1)>
				<CFSET TheFile = insert(SQL, TheFile, EndOfTagPos)>
				<CFSET Curpos = EndOfTagPos+1+len(SQL)>
			<CFELSE>
				<CFSET SQL = htmlCodeFormat(SQL)>
				<CFSET SQL = htmlCodeFormat(mid(TheFile, EndOfTagPos+1, endTagPos-EndOfTagPos-1))>
				<CFSET Fixable=false>
				<CFIF SQL does not contain "CFQUERYPARAM">
					<cfif queryType is "insert">
						<CFSET st = reFind("([']?##[^##]+##[']?)",SQL,1,true)>
						<CFLOOP Condition="#st.pos[1]#">
							<CFSET Fixable=true>
							<CFSET theParam = mid(SQL, st.pos[2], st.len[2])>
							<cfset newParam = "<strike>" & theParam>
							<CFIF left(theParam,1) IS "'">
								<CFSET theParam=mid(theParam,2,len(theParam)-2)>
							</CFIF>
							<cfif theParam contains "now()" or theParam contains "date">
								<cfset newParam = newParam & "</strike><b>&lt;CFQUERYPARAM Value=""#theParam#"" cfsqltype=""CF_SQL_TIMESTAMP""></b>">
							<cfelse>
								<cfset newParam = newParam & "</strike><b>&lt;CFQUERYPARAM Value=""#theParam#""></b>">
							</cfif>
							<CFSET SQL=removechars(SQL,st.pos[2],st.len[2])>
							<CFSET SQL=insert(newParam,SQL,st.pos[2]-1)>
							<CFSET st = reFind("([']?##[^##]+##[']?)",SQL,st.pos[1]+len(newParam),true)>
						</CFLOOP>
					<cfelse>
						<CFSET st = reFind("=[[:space:]]*([']?##[^##]+##[']?)",SQL,1,true)>
						<CFLOOP Condition="#st.pos[1]#">
							<CFSET Fixable=true>
							<CFSET theParam = mid(SQL, st.pos[2], st.len[2])>
							<cfset newParam = "<strike>" & theParam>
							<CFIF left(theParam,1) IS "'">
								<CFSET theParam=mid(theParam,2,len(theParam)-2)>
							</CFIF>
							<cfif theParam contains "now()" or theParam contains "date">
								<cfset newParam = newParam & "</strike><b>&lt;CFQUERYPARAM Value=""#theParam#"" cfsqltype=""CF_SQL_TIMESTAMP""></b>">
							<cfelse>
								<cfset newParam = newParam & "</strike><b>&lt;CFQUERYPARAM Value=""#theParam#""></b>">
							</cfif>
							<CFSET SQL=removechars(SQL,st.pos[2],st.len[2])>
							<CFSET SQL=insert(newParam, SQL, st.pos[2]-1)>
							<CFSET st = reFind("\=[[:space:]]*([']?##[^##]+##[']?)",SQL,st.pos[1]+st.len[1]+50+len(theParam),true)>
						</CFLOOP>
					</cfif>
				</CFIF>
				<CFOUTPUT>
				<CFIF Fixable><INPUT Type="Checkbox" Name="ffFixMe" Value="#SQLHash#" <cfif isDefaultChecked>CHECKED</cfif>>Parameterize Me:<br></CFIF>
				<pre>#htmlcodeformat(StartTag)##SQL#</pre>
				</CFOUTPUT>
				<CFSET curpos = endTagPos>
			</CFIF>
		</CFIF>
		<CFOUTPUT></TD></TR></CFOUTPUT>
		<CFSET curpos = findNoCase("<CFQUERY",TheFile,curpos)>
	</CFLOOP>
	<CFIF ReWrite>
		<cfif overwriteInPlace>
	   		<CFFILE Action="Write" 
				File="#CurDir#\#Dir.Name#.old"
			    OUTPUT="#TheOriginalFile#"
			    ADDNEWLINE="No"
			>
	   		<CFFILE Action="Write" 
				File="#CurDir#\#Dir.Name#"
			    OUTPUT="#TheFile#"
			    ADDNEWLINE="No"
			>
			<CFOUTPUT><TR><TD></TD><TD>File "#CurDir#\#Dir.Name#" written.  Old version saved as ".old"</TD></TR></CFOUTPUT>
		<cfelse>
	   		<CFFILE Action="Write" 
				File="#CurDir#\#Dir.Name#.new"
			    OUTPUT="#TheFile#"
			    ADDNEWLINE="No"
			>
			<CFOUTPUT><TR><TD></TD><TD>File "#CurDir#\#Dir.Name#.new" written.</TD></TR></CFOUTPUT>
		</cfif>
	</CFIF>
	<cfcatch type="any">
		<cfoutput>
		<TR><TD></TD><TD>
		<strong>Error parsing query:</strong>
		<pre>#htmlcodeformat(StartTag & SQL)#</pre>
		#cfcatch.message#<br>
		#cfcatch.detail#
		</TD></TR>
		<CFSET curpos = endTagPos>
		</cfoutput>
	</cfcatch>
	</cftry>
</CFIF>
<CFFLUSH>
</CFLOOP>
<CFOUTPUT>
<TR>
	<TD bgColor="eeeeee"><font face="arial"><b>Totals:</b></font></TD>
	<TD bgColor="eeeeee" Align="Right"><font face="arial">#numberFormat(TotalSize)#</font></TD>
	<TD bgColor="eeeeee" Align="Right"><font face="arial">#numberFormat(TotalLines)#</font></TD>
</TR>
</CFOUTPUT>
</TABLE>

<CFIF beRecursive>
<CFDIRECTORY Action="List" 
	Directory="#CurDir#" 
	Name="Dir">
<CFLOOP Query="Dir">
	<CFIF Dir.Type IS "Dir" AND left(Dir.Name,1) IS NOT ".">
		<CFMODULE template="_parameterizeQueries.cfm" CurDir="#CurDir#\#Dir.Name#">
	</CFIF>
</CFLOOP>
</CFIF>

<CFIF isDefined("Attributes.CurDir")>
	<CFSET Caller.TotalSize = Caller.TotalSize + TotalSize>
	<CFSET Caller.TotalLines = Caller.TotalLines + TotalLines>
<CFELSE>
	<CFOUTPUT>
	<TABLE>
	<TR>
		<TH bgColor="eeeeee">&nbsp;</TH>
		<TH bgColor="eeeeee"><font face="arial">Size</font></TH>
		<TH bgColor="eeeeee"><font face="arial">Lines</font></TH>
	</TR>
	<TR>
		<TD bgColor="eeeeee"><font face="arial"><b>Grand Totals:</b></font></TD>
		<TD bgColor="eeeeee" Align="Right"><font face="arial">#numberFormat(TotalSize)#</font></TD>
		<TD bgColor="eeeeee" Align="Right"><font face="arial">#numberFormat(TotalLines)#</font></TD>
	</TR>
	</TABLE>
	<INPUT Type="Submit" Value="Parameterize Selected">
	</FORM>
	</body>
	</html>
	</CFOUTPUT>
</CFIF>
