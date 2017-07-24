(* ::Package:: *)


(* ::Title:: *)
(*WebTools Package*)

(* ::Text::GrayLevel[.5]:: *)
(*Autogenerated BTools package*)

JSONTree::usage="Formats a JSON object as a tree";


JSONLookup::usage="Looks up attributes in a JSON object or object set";


JSONObject::usage=
	"Mutable JSON object for eason of manipulation. Can be renormalized out to plain JSON.";


SSHKeys::usage=
	"Lists the available SSH keys";
SSHKnownHosts::usage=
	"Lists the available known_hosts";
SSHAddHost::usage=
	"Adds a host to a host file";
SSHKeyCreate::usage=
	"Configures an SSH key pair in a given directory";
SSHConfigure::usage=
	"Configures an SSH tunnel to a given server";


XMLGenerate::usage=
	"Generates an XMLObject from data";
XMLDeploy::usage=
	"CloudExports an XMLObject";
XMLExport::usage=
	"Exports an XMLObject";
$CSStylesheets::usage=
	"A cache of named stylesheets";
MarkdownGenerate::usage=
	"Generates an XMLObject from a markdown string";


WebSiteDeploy::usage="Deploys a directory to the web";


Begin["`Private`"];


(*JSONTree[json_]:=;*)


JSONLookup[json:{__Rule}|{{__Rule}..},
	fields:(_String|_Integer|_List|_Symbol|_Map|_Select)..]:=
	Fold[
		Switch[#2,
			_Map|_Select,
				#2@#,
			_Integer|All|{__Integer},
				#[[#2]],
			_,
				Lookup[#,#2]
			]&,json,{fields}
		];
JSONLookup[
	fields:(_String|_Integer|_List|_Symbol|_Map|_Select)..][
		json:{__Rule}|{{__Rule}..}]:=
	JSONLookup[json,fields];


$SSHDirectory=
	Switch[$OperatingSystem,
		"Windows",
			"???",
		_,
			FileNameJoin@{$HomeDirectory,".ssh"}
		];


RSAImportChunks[rsa_String]:=
	StringCases[rsa,
		"-----"~~Except["\n"]..~~"-----\n"~~
			block:Shortest[__]~~
			"-----"~~Except["\n"]..~~("\n"|EndOfString):>
		block
		];


RSAParseBlock[block_]:=
	If[Length@#>1,
		<|
			"Header"->
				StringJoin@Riffle[First@#,"\n"],
			"Key"->
				StringJoin@Riffle[Last@#,"\n"]
			|>,
		<|
			"Key"->
			StringJoin@Riffle[First@#,"\n"]
			|>
		]&@
		With[{lines=StringSplit[block,"\n"]},
			With[{pos=
				FirstPosition[lines,_String?(StringLength[#]==64&),None,{1}]
				},
				If[pos=!=None,
					{
						Take[lines,{1,First@pos-1}],
						Take[lines,{First@pos,-1}]
						},
					{{}}
					]
				]
			];


RSAImportString[rsa_String]:=
	Replace[RSAParseBlock/@RSAImportChunks[rsa],
		{b_}:>
			b
		];
RSAImport[f_String?(FileExistsQ)]:=
	RSAImportString[Import[f,"Text"]]


SSHKeys[dir_String?DirectoryQ]:=
	AssociationMap[
		<|
			"Private"->
				RSAImport@FileNameJoin@{dir,#},
			"Public"->
				StringSplit[Import[FileNameJoin@{dir,#<>".pub"},"Text"]][[2]]
			|>&,
		FileNameTake/@FileNames["*_rsa",dir]
		];
SSHKeys[Optional[Automatic,Automatic]]:=
	SSHKeys@$SSHDirectory;


SSHKnownHostImportString[hostString_]:=
	If[Length@#==3,
		<|
			"HostName"->None,
			"HostIPAddress"->#[[1]],
			"HostKey"->#[[3]]
			|>,
		<|
			"HostName"->#[[1]],
			"HostIPAddress"->#[[2]],
			"HostKey"->#[[4]]
			|>
		]&@StringSplit[hostString,Whitespace|",",4]


SSHKnownHostImport[hostFile_]:=
	SSHKnownHostImportString/@
		StringSplit[
			Import[hostFile,"Text"],
			"\n"
			];


SSHKnownHosts[dir_String?DirectoryQ]:=
	Flatten[
		SSHKnownHostImport/@
			FileNames["known_hosts",dir]
		];
SSHKnownHosts[Optional[Automatic,Automatic]]:=
	SSHKnownHosts@$SSHDirectory;


SSHHostString::noip=
	"No \"HostIPAddress\" provided";
SSHHostString::nokey=
	"No \"HostKey\" provided";
Options[SSHHostString]={
	"HostName"->None,
	"HostIPAddress"->None,
	"HostKey"->None
	};
SSHHostString[ops:OptionsPattern[]]:=
	With[{
		name=
			Replace[OptionValue["HostName"],
				Except[_String]->Nothing
				],
		ip=
			Replace[OptionValue["HostIPAddress"],
				Except[_String]->
					(Message[SSHHostString::noip];$Failed)
				],
		key=
			Replace[OptionValue["HostKey"],
				Except[_String]->
					(Message[SSHHostString::nokey];$Failed)
				]
		},
		If[AllTrue[{name,ip,key},StringQ],
			StringRiffle@{name,ip,key}<>"\n",
			$Failed]
		];


Options[SSHAddHost]=
	Options@SSHHostString;
SSHAddHost[hostList:{__Association},ops:OptionsPattern[]]:=
	With[{
		name=OptionValue["HostName"],
		ip=OptionValue["HostIPAddress"],
		key=OptionValue["HostKey"]
		},
		If[AllTrue[{ip,key},StringQ],
			With[{hosts=
				#[[{"HostName","HostIPAddress"}]]->#[["HostKey"]]&/@
					hostList},
				Prepend[hosts,
					<|
						"HostName"->name,
						"HostIPAddress"->ip
						|>->key
						]
				],
			$Failed
			]
		];
SSHAddHost[hostFile_String?FileExistsQ,ops:OptionsPattern[]]:=
	SSHAddHost[HSSHKnownHostImport@hostFile]
SSHAddHost[Optional[Automatic,Automatic],ops:OptionsPattern[]]:=
	SSHAddHost[First@FileNames["known_hosts",$SSHDirectory]]


xmlObjectTemplate=
	TemplateObject[
		XMLObject["Document"][
			{XMLObject["Declaration"]["Version"->"1.0","Standalone"->"yes"]},
			XMLElement["html",
				{
					"version"->
						"-//W3C//DTD HTML 4.01 Transitional//EN","lang"->"en",
					{"http://www.w3.org/2000/xmlns/","xmlns"}->
						"http://www.w3.org/1999/xhtml"
					},
				{
					TemplateSlot["header"],
					TemplateSlot["body"]
					}
				],
			{}
			]
		];


cssPropRules=
	{
		FontColor->"color",
		FrameStyle->"border",
		FrameMargins->"margin",
		TextAlignment->"text-align",
		TabSpacings->"tab-size",
		SourceLink->"src",
		ButtonFunction->
			"onclick",
		Annotation->"alt",
		Hyperlink->"href",
		RoundingRadius->"border-radius",
		LineSpacing->"line-height",
		ImageSize->{"width","height"},
		e_:>
			ToLowerCase[
				StringJoin@{
					StringTake[#,1],
					StringReplace[StringDrop[#,1],
						l:LetterCharacter?(Not@*LowerCaseQ):>"-"<>l]
					}&@ToString[e]
				]
		};


cssValRules:=
	cssValRules=
		Join[
			Map[
				Replace[#,
					Hold[c_]:>
						(c->ToLowerCase@ToString[Unevaluated[c]])
					]&,
				Thread@Hold@{
					Red,White,Blue,Black,Yellow,
					Green,Orange,Purple,Pink,Gray,
					LightBlue,LightRed,LightGray,LightYellow,
					LightGreen,LightOrange,LightPurple,LightPink,
					Thick,Dotted,Thin,Dashed
					}],{
			c_?ColorQ:>
				"#"<>Map[
					StringPadLeft[
						IntegerString[#,16],
						2,
						"0"
						]&,
					Floor[255*Apply[List,ColorConvert[c,RGBColor]]]
					],
			i_Integer:>
				ToString[i]<>"px",
			q_Quantity:>
				StringReplace[
					ToString[q],
					" "->""
					],
			Scaled[i_]:>
				ToString@Floor[i*100]<>"%",
			r_Rule:>
				(cssGenerate[r]),
			{l__}|Directive[l__]:>
				StringRiffle@Map[#/.cssValRules&,{l}],
			i_:>ToLowerCase@ToString[i]
			}
		];


cssTypeRules={
	"Title"->"h1",
	"Subtitle"->"h2",
	"Section"->"h3",
	"Subsection"->"h4",
	"Subsubsection"->"h5",
	"Subsubsubsection"->"h6",
	"Hyperlink"->"a",
	"HyperlinkActive"->"a:hover",
	"Graphics"->"img",
	"Text"->"p",
	s_String:>(ToLowerCase[s])
	};


cssThreadedOptions[propBase_,propOps_,vals_]:=
	MapThread[
		If[!MatchQ[#2,Inherited|None],
			If[StringContainsQ[propBase,"-"],
				StringReplace[propBase,{
					"-"->("-"<>#<>"-")
					}]->(#2/.cssValRules),
				StringJoin[propBase,"-"<>#]->(#2/.cssValRules)
				],
			Nothing
			]&,{
		propOps,
		vals
		}]


cssGenerate//Clear;
cssGenerate[
	prop_->val:Except[{__Rule}],
	joinFunction_:Automatic]:=
	With[{
		propBase=
			prop/.cssPropRules
		},
		If[Not@ListQ@propBase,
			Sequence@@
				Map[
					Replace[joinFunction,
						Automatic->(StringJoin@{First@#,": ",Last@#,";"}&)
						],
					Replace[val,{
						{{l_,r_},{b_,h_}}:>
							If[StringContainsQ[propBase,"radius"],
								cssThreadedOptions[
									propBase,
									{"left-bottom","right-bottom","left-top","right-top"},
									{l,r,b,h}
									],
								cssThreadedOptions[
									propBase,
									{"left","right","bottom","top"},
									{l,r,b,h}
									]
								],
						{l_,r_}:>
							cssThreadedOptions[
								propBase,
								{"left","right"},
								{l,r}
								],
						v_:>
							{propBase->(v/.cssValRules)}
						}]
					],
			If[ListQ@val,
				Sequence@@cssGenerate[Thread[propBase->val],joinFunction],
				cssGenerate[First@propBase->val,joinFunction]
				]
			]
		];
cssGenerate[
	type:_String|_Symbol->spec:{__Rule},
	joinFunction_:Automatic]:=
	TemplateApply["`type` {\n\t`rules`\n\t}",
		<|
			"type"->(ToString[type]/.cssTypeRules),
			"rules"->
				StringRiffle[cssGenerate[#,joinFunction]&/@spec,
					"\n\t"]
			|>
		];
cssGenerate[
	r:{__Rule},
	joinFunction_:Automatic]:=
	Replace[joinFunction,{
		Automatic:>
			Flatten@{
				"\n",
				Riffle[cssGenerate/@r,"\n\n"],
				"\n"
				},
		j_:>
			(cssGenerate[#,j]&/@r)
		}];
cssGenerate[a_Association]:=
	KeyValueMap[cssGenerate,a];
cssGenerate[{},Optional[_,_]]:={};


xmlOptionsConvert[o_]:=
	Replace[o,{
		(k_->r:{__Rule}):>
			(k/.cssPropRules)->
				StringJoin@
					ReplaceAll[xmlOptionsConvert@r,
						(op_->val_):>
							op<>":"<>val<>";"
						],
		r_Rule:>
			cssGenerate[r,Identity]
		},
		1]


$xmlObjectRecursiveConversion=
	xmlObjectConvert;


Clear@xmlObjectConvert;
xmlObjectConvert[x_XMLObject]:=
	x;
xmlObjectConvert[XMLElement[a_,m_,e_]]:=
	XMLElement[a,m,$xmlObjectRecursiveConversion/@e];
xmlObjectConvert[type_->r_]:=
	XMLElement[type,{},$xmlObjectRecursiveConversion@r];


xmlObjectConvert[Hyperlink[a_,b:Except[_Rule]:None,o___]]:=
	XMLElement["a",
		Join[
			{"href"->Replace[b,Except[_String]->a]},
			xmlOptionsConvert@{o}
			],
		{a}]
xmlObjectConvert[Hyperlink[a_,b:Except[_Rule]:None,___]]:=
	XMLElement["a",
		{"href"->Replace[b,Except[_String]->a]},
		{a}];


xmlObjectConvert[Button[e_,b:Except[_Rule]:None,o___]]:=
	XMLElement["button",
		xmlOptionsConvert@{
			ButtonFunction->Function[b](*,
			o*)
			},
		{$xmlObjectRecursiveConversion@e}
		];


xmlObjectConvert[
	Column[e_,
		riffle:Except[_Rule]:"\n",
		o___]]:=
	XMLElement["div",
		cssGenerate[{o},Identity],
		$xmlObjectRecursiveConversion/@Riffle[e,riffle]
		];


xmlObjectConvert[
	Row[s_,
		riffle:Except[_Rule]:Nothing,
		o___]]:=
	XMLElement["span",
		cssGenerate[{o},Identity],
		$xmlObjectRecursiveConversion/@Riffle[s,riffle]
		];


xmlObjectConvert[Graphics[s_String,___]]:=
	XMLElement["img",
		{"src"->s,"alt"->""},
		{}
		];


xmlObjectConvert[g:Graphics[_,o___]]:=
	XMLElement["img",
		xmlOptionsConvert@{
			SourceLink->
			If[$xmlAutoExport,
				First@CloudExport[Rasterize@g,"GIF",Permissions->"Public"],
				""
				],
			Annotation->""
			},
		{}
		];
xmlObjectConvert[EmbeddedHTML[src_,ops___]]:=
	XMLElement["iframe",
		xmlOptionsConvert@{
			SourceLink->src,
			ops
			},
		{}
		];


xmlObjectConvert[Grid[g_,o___]]:=
	XMLElement["table",
		cssGenerate[{o},Identity],
		XMLElement["tr",
			{},
			$xmlObjectRecursiveConversion@
				Thread["td"->#]&/@g
			]
		];


xmlObjectConvert[Panel[e_,o___]]:=
	XMLElement["div",
		With[{
			classes=Cases[{o},Except[_Rule]],
			props=Cases[{o},_Rule]
			},
			cssGenerate[
				Join[
					If[Length@classes>0,
						Thread["Class"->classes],
						classes
						],
					props
					],
				Identity
				]
			],
		{$xmlObjectRecursiveConversion@e}
		];


xmlBuildStyles//Clear;
xmlBuildStyles[e_,Italic|(FontSlant->Italic)]:=
	XMLElement["i",{},{e}];
xmlBuildStyles[e_,"Underline"|(FontVariations->{"Underline"->True})]:=
	XMLElement["u",{},{e}];
xmlBuildStyles[e_,Bold|(FontWeight->Bold)]:=
	XMLElement["b",{},{e}];
xmlBuildStyles[e_,"StrikeThrough"|(FontVariations->{"StrikeThrough"->True})]:=
	XMLElement["s",{},{e}];
xmlBuildStyles[e_,o:{__}]:=
	Fold[xmlBuildStyles,e,o];
xmlBuildStyles[e_,_]:=
	e;


xmlObjectConvert["\n"]:=
	XMLElement["br",{},{}];
xmlObjectConvert[Style[e_,s:_String:"span",o___]]:=
	xmlBuildStyles[
		XMLElement[s/.cssTypeRules,
			xmlOptionsConvert@Cases[{o},_Rule],
			Flatten@{$xmlObjectRecursiveConversion@e}
			],
		Cases[{o},Except[_Rule]]
		];


xmlObjectConvert[l_List]:=
	$xmlObjectRecursiveConversion/@l;
xmlObjectConvert[e_]:=
	ToString[e];


Options[xmlGenerateHeader]={
	"Title"->"Web Page",
	"Meta"->{"charset"->"utf8"},
	"Style"->{}
	};
xmlGenerateHeader[ops:OptionsPattern[]]:=
	With[{
		t=
			OptionValue["Title"],
		m=
			OptionValue["Meta"],
		s=
			Replace[OptionValue["Style"],{
				css_String:>
					If[KeyMemberQ[$CSStylesheets,css],
						$CSStylesheets[css],
						css
						],
				r:Except[{(_String->_List)..}]:>
					"body"->r
				}]
		},
		XMLElement["head",{},
			{
				XMLElement["title",{},{t}],
				XMLElement["meta",m,{}],
				Replace[s,{
					f_String:>
						XMLElement["style",{},{"\n@import url(",f,")"}],
					_:>
						Replace[cssGenerate@s,{
							l:{__}:>
								XMLElement["style",{},l],
							s_String:>
								XMLElement["style",{},{s}],
							_->Nothing
							}]
					}]
				}]
		]


xmlGenerateBody[data_]:=
	XMLElement["body",{},
		Replace[xmlObjectConvert@data,
			e:Except[_List]:>{e}
			]
		];


Options[XMLGenerate]=
	Options[xmlGenerateHeader];
XMLGenerate[expr_,ops:OptionsPattern[]]:=
	TemplateApply[xmlObjectTemplate,
		<|
			"body"->xmlGenerateBody[expr],
			"header"->xmlGenerateHeader[ops]
			|>]


Options[XMLDeploy]:=
	Join[
		Options@CloudExport,
		Options@XMLGenerate
		];
XMLDeploy[xml:XMLObject[___][___]|_XMLElement|_XMLObject,
	uri:_String|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	If[uri===Automatic,
		CloudExport[ExportString[xml,"XML"],"HTML",
			FilterRules[{ops},Options@CloudExport]
			],
		CloudExport[ExportString[xml,"XML"],"HTML",uri,
			FilterRules[{ops},Options@CloudExport]
			]
		];
XMLDeploy[expr_,
	uri:_String|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	XMLDeploy[
		XMLGenerate[expr,
			FilterRules[{ops},Options@XMLGenerate]],
		uri,
		ops
		]


Options[XMLExport]:=
	Join[
		Options@XMLGenerate
		];
XMLExport[
	xml:XMLObject[___][___]|_XMLElement|_XMLObject,
	filePath_String,
	ops___]:=
	Export[
		filePath,
		ExportString[xml,"XML"],
		"Text",
		ops
		];


$CSStylesheets=<|
	"Markdown"->
		{
			"body"->{
				Background->Lighter[LightBlue,.9],
				FontFamily->"Arial"
				},
			".markdown-content"->{
				Background->White,
				FrameStyle->{
					{Directive[1,"solid",LightGray],Directive[1,"solid",LightGray]},
					{Directive[1,"solid",LightGray],Directive[65,"solid",GrayLevel[.65]]}
					},
				RoundingRadius->5,
				Padding->{
					{50,50},
					{0,0}
					},
				"MinHeight"->Scaled[.9]
				},
			"Title"->{
				FrameStyle->{
					{Inherited,Inherited},
					{Directive[1,"solid",LightGray],Inherited}
					}
				},
			"Subtitle"->{
				FontColor->GrayLevel[.3]
				},
			"Section"->{
				FontColor->GrayLevel[.3]
				},
			"Subsection"->{
				FontColor->GrayLevel[.4]
				},
			"Subsubsection"->{
				FontColor->GrayLevel[.4]
				},
			"Subsubsubsection"->{
				FontColor->GrayLevel[.5]
				},
			"Code"->{
				Background->GrayLevel[.95],
				FontWeight->Bold,
				FontSize->12,
				RoundingRadius->5,
				Padding->3
				},
			"Text"->{
				LineSpacing->1.2
				}
			},
	"Wolfram"->
		{
			"Title"->{
				Background->None,
				FontColor->RGBColor[0.8, 0.043, 0.008],
				FontSize->44,
				FrameStyle->False,
				FrameMargins->{{27,Inherited},{10,30}},
				Padding->8
				},
			"Subtitle"->{
				Background->None,
				FontColor->GrayLevel[0.3],
				FontSize->24,
				FrameStyle->False,
				FrameMargins->{{27,Inherited},{20,2}},
				Padding->8
				},
			"Section"->{
				Background->None,
				FontColor->RGBColor[0.7612268253604944, 0.29576562142366675`, 0.08555733577477684],
				FontSize->28,
				FrameStyle->{{0,0},{0,1}},
				FrameMargins->{{27,Inherited},{8,18}},
				Padding->4
				},
			"Subsection"->{
				Background->None,
				FontColor->RGBColor[0.778286411841001, 0.4230563820859083, 0.16115053025101092`],
				FontSize->20,
				FrameStyle->False,
				FrameMargins->{{50.34765625`,3.`},{8.`,12.`}},
				Padding->8
				},
			"Subsubsection"->{
				Background->None,
				FontColor->RGBColor[0.7143816281376364, 0.21776150148775464`, 0.03341725795376516],
				FontSize->19,
				FrameStyle->False,
				FrameMargins->{{66,Inherited},{2,10}},
				Padding->8
				},
			"Subsubsubsection"->{
				Background->None,
				FontColor->RGBColor[0.778286411841001, 0.4230563820859083, 0.16115053025101092`],
				FontSize->14,
				FrameStyle->False,
				FrameMargins->{{66,Inherited},{2,10}},
				Padding->8
				},
			"Input"->{
				Background->None,
				FontColor->Automatic,
				FontSize->13,
				FontWeight->"Bold",
				FrameStyle->False
				},
			"Code"->{
				FontColor->Automatic,
				FontSize->12,
				FontWeight->"Bold",
				FrameStyle->False,
				Background->GrayLevel[.95],
				RoundingRadius->5,
				Padding->3
				},
			"Output"->{
				Background->None,
				FontColor->Automatic,
				FontSize->13,
				FrameStyle->False,
				FrameMargins->{{66,10},{10,5}},
				Padding->8
				},
			"Text"->{
				Background->None,
				FontColor->Automatic,
				FontSize->12,
				FrameStyle->False,
				FrameMargins->{{66,10},{0,7}},
				Padding->8
				}
			}
		(*Map[
			With[{s=#},
				s\[Rule]
					Map[
						If[Length@#>0,Last@#,#]\[Rule]
							AbsoluteCurrentValue[EvaluationNotebook[],
								{StyleDefinitions,s,
									If[Length@#>0,First@#,#]}]&,{
						Background,
						FontColor,
						FontSize,
						FontWeight,
						CellFrame->FrameStyle,
						CellMargins\[Rule]FrameMargins,
						CellFrameMargins\[Rule]Padding
						}]
				]&,{
			"Title","Subtitle","Section",
			"Subsection","Subsubsection","Subsubsubsection",
			"Input","Code","Output"
			}]//Map[First@#\[Rule]NewlineateCode@Last@#&]//NewlineateCode*)
	|>;


markdownFormatHeaders[par_]:=
	StringReplace[par,{
		l:(StartOfLine~~"#"~~Except["\n"]..):>
			Style[
				StringTrim[l,("#"|Whitespace)..],
				Replace[StringLength@StringTrim[l,Except["#"]..],{
					1->"Title",
					2->"Subtitle",
					3->"Section",
					4->"Subsection",
					5->"Subsubsection",
					6->"Subsubsubsection"
					}]
				]
		}];
markdownFormatLinks[par_]:=
	StringReplace[par,
		"["~~lab:Except["]"]..~~"]"~~"("~~link:Except[")"]..~~")":>
			Hyperlink[lab,link]
		];
markdownFormatTicks[par_]:=
	StringReplace[par,
		("```"~~t:Shortest[__]..~~"```"):>
			XMLElement["code",{},{t}]
		];
markdownFormatHTML[par_]:=
	StringReplace[par,{
		xml:
			("<"~~Except["/"|">"]..~~">"~~
				Except["<"]..~~"</"~~Except[">"]..~~">")|
			("<"~~Except[">"]~~"/>"):>
			Replace[ImportString[xml,"XML"],{
				XMLObject[_][_,x_,___]:>x,
				$Failed:>xml
				}]
		}];
markdownFormat[par_,parStyle_:"p"]:=
	Replace[markdownFormatHeaders[par],{
		s_String:>
			Replace[markdownFormatLinks[s],{
				html_String:>
					Replace[markdownFormatHTML[html],{
						ticks_String:>
							Replace[markdownFormatTicks[ticks],{
								StringExpression[e__]:>
									Row@
										Replace[{e},
											p_String:>
												markdownFormat[p,"span"],
											1]
								}],
						StringExpression[e__]:>
							Row@
								Replace[{e},
									p_String:>
										markdownFormat[p,"span"],
									1]
						}],
				StringExpression[e__]:>
					Style[
						Row@
							Replace[{e},
								p_String:>
									markdownFormat[p,"span"],
								1],
						"p"
						]
				}],
		StringExpression[e__]:>
			Column@
				Replace[{e},
					s_String:>
						markdownFormat[s,parStyle],
					1]
		}]


Options[MarkdownGenerate]:=
	Options@XMLGenerate;
MarkdownGenerate[
	md_String?(Not@*FileExistsQ),
	css:_String|{___Rule}|Automatic:Automatic,
	ops:OptionsPattern[]]:=
	With[{pars=StringSplit[md,"\n\n"]},
		XMLGenerate[
			Panel[
				Column[Map[Style[markdownFormat[#],"Text"]&,pars],Nothing],
				"markdown-content"
				],
			"Style"->
				Replace[css,
					Automatic->"Markdown"],
			ops
			]
		];
MarkdownGenerate[
	f_String?FileExistsQ,
	css:_String|{___Rule}|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	MarkdownGenerate[Import[f,"Text"],css,ops]


Options[WebSiteDeploy]=
	Join[
		{
			FileNameForms->"*@.@*"
			},
		Options[CloudObject]
		];
WebSiteDeploy[
	outDir_String?DirectoryQ,
	uri:_String|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	CopyFile[
		#,
		URLBuild@{
			Replace[uri,Automatic:>FileBaseName[outDir]],
			FileNameSplit@
				FileNameDrop[
					#,
					FileNameDepth[outDir]
					]
			}
		]&/@
		Select[FileExistsQ]@
			FileNames[
				Replace[
					OptionValue[FileNameForms],
					All->"*"
					],
				outDir,
				\[Infinity]];


End[];



