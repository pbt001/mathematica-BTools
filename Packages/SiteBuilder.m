(* ::Package:: *)



WebSiteInitialize::usage="Makes a new website in a directory";
WebSiteOptions::usage="Gets configuration options for a website";
WebSiteSetOptions::usage="Sets configuration options for a website";
WebSiteNew::usage="Makes a new post notebook";
WebSiteBuild::usage="Builds a website";
WebSiteDeploy::usage="Deploys a directory to the web";


Begin["`Private`"];


$WebSiteDirectory=
	FileNameJoin@{
		$UserBaseDirectory,
		"ApplicationData",
		"WebSites"
		}


WebSiteInitialize[dir_String?(DirectoryQ@*DirectoryName),
	ops:OptionsPattern[]
	]:=
	(
		CopyDirectory[
			PackageFilePath["Resources","Templates","WebSite"],
			dir
			];
		Export[FileNameJoin@{dir,"SiteConfig.wl"},{ops}];
		dir
		);


(*WebSiteInitialize[s_String?(Not@FileExistsQ[#]&&StringFreeQ[#,$PathnameSeparator]&)]:=
	(
		If[!DirectoryQ@$WebSiteDirectory,
			CreateDirectory[$WebSiteDirectory,CreateIntermediateDirectories\[Rule]True]
			];
		With[{r=
			WebSiteInitialize@
				FileNameJoin@{
					$WebSiteDirectory,
					s
					}
			},
			r/;DirectoryQ[r]
			]
	)*)


WebSiteOptions[dir_String?(DirectoryQ@*DirectoryName)]:=
	Replace[Quiet@Import[FileNameJoin@{dir,"SiteConfig.wl"}],
		Except[_?OptionQ]->
			{}
		]


WebSiteSetOptions[dir_String?(DirectoryQ@*DirectoryName),
	ops:OptionsPattern[]
	]:=
	Export[FileNameJoin@{dir,"SiteConfig.wl"},
		Merge[
			{
				WebSiteOptions[dir],
				ops
				},
			Last
			]
		];


WebSiteNew[
	dir_String?DirectoryQ,
	place_String,
	name:_String|Automatic:Automatic,
	ops:OptionsPattern[]
	]/;DirectoryQ@FileNameJoin@{dir,"content",place}:=
	With[{
		autoname=
			StringTrim[#,"."<>FileExtension[#]]<>".nb"&@
				Replace[name,
					Automatic:>
						"Post #"<>ToString@Length@
						DeleteDuplicatesBy[FileBaseName]@
							FileNames["*.nb"|"*.md",FileNameJoin@{dir,"content",place}]
					]
		},
		If[!FileExistsQ@FileNameJoin@{dir,"content",place,autoname},
			SystemOpen@
			Export[FileNameJoin@{dir,"content",place,autoname},
				Notebook[{
					Cell[
						BoxData@ToBoxes@
							Merge[{
								Switch[place,
									"posts",
										<|
											"Title"->"< Post Title >",
											"Slug"->Automatic,
											"Date"->Now,
											"Tags"->{},
											"Authors"->{},
											"Categories"->{}
											|>,
									"pages",
										<|
											"Title"->"< Page Title >",
											"Slug"->Automatic
											|>,
									_,
										<|
											"Title"->"< Title >",
											"Slug"->Automatic
											|>
									],
								{ops}
								},
								Last
								],
						"Metadata"
						],
					Cell[
						"Supports: Section, Subsection, Subsubsection, Text, Code, Item, Quote, and NonWLCode styles",
						"Text"
						],
					Switch[place,
						"posts",
							Cell[
								"This is a post, so article.html is the theme template for it.",
								"Text"
								],
						"pages",
							Cell[
								"This is a page, so page.html is the theme template for it.",
								"Text"
								],
						_,
							Nothing
						]
					},
					StyleDefinitions->
						FrontEnd`FileName[Evaluate@{$PackageName},
							"MarkdownNotebook.nb"
							]
					]
				],
			$Failed
			]
		]


(*WebSiteNew[
	dir_String?(Not@FileExistsQ[#]&&StringFreeQ[#,$PathnameSeparator]&),
	place_String,
	name:_String|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		d=
			If[DirectoryQ@
				FileNameJoin@{
					$WebSiteDirectory,
					dir
					},
				WebSiteNew[
					FileNameJoin@{
						$WebSiteDirectory,
						dir
						},
					place,
					name,
					ops
					]
				]
	},
	d/;(d===$Failed||FileExistsQ[d])
	]*)


$TemplateLibDirectory=
	PackageFilePath["Resources","Themes","template_lib"];


WebSiteXMLTemplateApply[
	root:_String|{__String}|Automatic:Automatic,
	template:(_String|_File)?FileExistsQ,
	args:_?OptionQ:{}
	]:=
	Replace[
		Block[{
				$TemplatePath=
					Join[
						Flatten@List@
							Replace[root,Automatic:>DirectoryName@template],
						{
							$TemplateLibDirectory
							},
						$TemplatePath
						],
				$Path=
					Join[
						Flatten@List@
							Replace[root,Automatic:>DirectoryName@template],
						{
							$TemplateLibDirectory
							},
						$Path
						],
				$ContextPath=
					Join[{"Templating`lib`",$Context},$ContextPath],
				$Context=
					"Templating`lib`"
				},
			Unprotect[Templating`lib`$$templateLib];
			Clear[Templating`lib`$$templateLib];
  		Import[FileNameJoin@{"include","lib","loadTemplateLib.m"}];
			(Remove["Templating`lib`*"];#)&@
				Nest[
					TemplateApply[
						XMLTemplate[#],
						args
						]&,
					File[template],
					1
					]
			],
		{
			s_String:>
				StringReplace[s,
					Repeated[(Whitespace?(StringFreeQ["\n"])|"")~~"\n",{2,\[Infinity]}]->"\n"
					]
			}
		]


WebSiteBuildSlug[fname_]:=
	StringReplace[StringTrim[fname],WhitespaceCharacter->"-"]


WebSiteBuildURL[fname_]:=
	URLBuild@FileNameSplit@
		WebSiteBuildSlug@fname


WebSiteBuildContentType[fname_,dir_]:=
	If[StringStartsQ[fname,dir],
		Replace[
			FileNameTake[
				If[FileNameTake[#,1]=="content",
					FileNameDrop[#,1],
					#
					]&@
					FileNameDrop[fname,FileNameDepth@dir],
				1
				],
			{
				"posts"->"post",
				"pages"->"page",
				_->"misc"
				}
			],
		"misc"
		]


$WebSiteContentDirectoryTemplateMap=
	<|
		"post"->"article.html",
		"page"->"page.html",
		"misc"->"base.html"
		|>;


WebSiteBuildGetTemplates[content_,dir_]:=
	Replace[
		Fold[
			Lookup[#,#2,<||>]&,
			{$ContentStack,"Attributes","Templates"}
			],
		{
			s_String:>
				StringTrim@StringSplit[s,","],
			Except[_String|{__String}]:>
				Lookup[$WebSiteContentDirectoryTemplateMap,
					WebSiteBuildContentType[
						content,
						longDir
						],
					"base.html"
					]
			}
		]


WebSiteBuildFilePath[fname_,dir_]:=
	If[StringStartsQ[fname,dir],
		If[FileNameTake[#,1]=="posts",
			FileNameDrop[#,1],
			#
			]&@
			If[FileNameTake[#,1]=="content",
				FileNameDrop[#,1],
				#
				]&@
				FileNameDrop[fname,FileNameDepth@dir],
		FileNameTake[fname]
		]


WebSiteTemplatePreProcess[fileContent_,args_]:=
	With[{
		lang=
			Lookup[args,"CodeLanguage"],
		prettyprint=
			Lookup[args,"PrettyPrint"],
		srcbase=
			Lookup[args,"SiteURL"]
		},
		If[StringQ[srcbase],
			ReplaceAll[
				#,
				("src"->f_):>
					("src"->StringReplace[f,"{filename}"->srcbase])
				]&,
			Identity
			]@
		If[TrueQ[prettyprint],
			ReplaceRepeated[
				#,
				XMLElement["pre",
					c_?(
							(TrueQ[prettyprint]&&
								StringFreeQ[Lookup[#,"class",""],"prettyprint"]
								)
							&),
					e:{XMLElement["code",___]}
					]:>
						XMLElement["pre",
							Normal@
								Append[
									Association@c,
									"class"->
										StringTrim[
											Lookup[c,"class",""]<>
												"prettyprint"
											]
									],
							e
							]
				]&,
			Identity
			]@
		If[StringQ[lang],
			ReplaceRepeated[
				#,
				XMLElement["code",
					c_?(
							(StringQ[lang]&&
								StringFreeQ[Lookup[#,"class",""],"language-"]
								)
							&),
					e_]:>
					XMLElement["code",
						Normal@
							Append[
								Association@c,
								"class"->
									StringTrim[
										Lookup[c,"class",""]<>
											" language-"<>ToLowerCase@lang
										]
								],
						e
						]
				]&,
			Identity
			]@
			FirstCase[
				fileContent,
				XMLElement["body",_,b_]:>
					b,
				fileContent,
				\[Infinity]
				]
		]


$WebSiteSummaryBaseUnits=
	{
		"Characters","Words","Characters",
		"Sentences","Paragraphs","Lines"
		};
$WebSiteSummaryIndependentUnits:=
	$WebSiteSummaryIndependentUnits=
		Quantity/@$WebSiteSummaryBaseUnits//QuantityUnit;
$WebSiteSummaryUnits:=
	$WebSiteSummaryUnits=
		Alternatives@@
			Join[$WebSiteSummaryBaseUnits,$WebSiteSummaryIndependentUnits]


WebSiteTemplateGatherArgs[fileContent_,args_]:=
	With[
		{
			content=
				Replace[fileContent,{
						l:{__XMLElement}:>
							StringRiffle[
								ExportString[#,"XML"]&/@l,
								"\n"
								],
						x_XMLElement:>
							ExportString[x,"XML"],
						None->
							"",
						e:Except[_String]:>
							(Message[WebSiteBuild::nocnt,Short[e]])
						}]
			},
		Merge[
			{
				Replace[
					FirstCase[
						If[StringQ[fileContent],
							ImportString[fileContent,"HTML"],
							fileContent
							],
						t:XMLElement["title",_,_]:>
							System`Convert`XMLDump`getSymbolicXMLPlaintext@
								XMLElement["body",{},t],
						None,
						\[Infinity]
						],
					{
						Except[_String]->
							Nothing,
						s_String:>
							("Title"->s)
						}
					],
				"Summary"->
					With[{
						sl=
							Replace[
								Lookup[args,"SummaryLength"],{
									i_Integer?Positive:>
										Quantity[i,"Characters"],
									q:Quantity[_Integer?Positive,$WebSiteSummaryUnits]:>
										q,
									_:>
										Quantity[1,"Paragraph"]
								}]
						},
						With[
							{
								cont=ImportString[content,"HTML"]
								},
							Replace[sl,{
								Quantity[i_,
									"Characters"|IndependentUnit["characters"]
									]:>
									Function[
										If[
											StringLength[#]>i,
											StringTake[#,i-3]<>"...",
											#
											]
										]@
										StringReplace[cont,Whitespace->" "],
								Quantity[i_,
									"Lines"|IndependentUnit["lines"|"lines of code"]
									]:>
									StringRiffle@
										Take[
											StringSplit[cont,"\n"],
											UpTo[i]
											],
								Quantity[i_,IndependentUnit[t_]|t_]:>
									StringRiffle[
										TextCases[cont,
											ToUpperCase[StringTake[#,1]]<>
												StringDrop[#,1]&@t,
											i],
										" "
										]
								}]
							]
						],
				"Date"->
					Replace[
						Lookup[args,"Date",Now],
						s_String:>DateObject[s]
						],
				args,
				"SiteName"->
					Replace[
						Lookup[args,"SiteName",Automatic],
						{
							s_String:>
								URLParse[s,"Path"][[-1]],
							Except[_String]:>
								Replace[
									Lookup[args,"SiteURL"],
									{
										s_String:>
											URLParse[s,"Path"][[-1]],
										Except[_String]:>
											Replace[Lookup[args,"SiteDirectory"],
												Except[_String]:>
													Replace[$WolframID,{
														s_String:>
															StringSplit[s,"@"][[1]],
														_->$UserName
														}]
												]
										}
									]
							}
						],
				"SiteURL"->
					Replace[
						Lookup[args,"SiteURL",Automatic],
						Automatic:>
							With[{
								bit=
									Length@
										Replace[
											Lookup[args,"URL",
												FileNameSplit@
													Lookup[args,"FilePath","??"]
												],
											s_String:>
												URLParse[s,"Path"]
											]
								},
								Replace[
									bit,
									{
										1->".",
										n_:>
											URLBuild@ConstantArray["..",n-1]
										}
									]
								]
						],
				With[{
					url=Lookup[args,"URL"],
					slug=Lookup[args,"Slug"],
					fp=Lookup[args,"FilePath"]
					},
					Which[
						StringQ@url,
							"URL"->url,
						StringQ@slug,
							"URL"->
								If[StringQ[fp],
									URLBuild@
										Append[Most@FileNameSplit[fp],slug<>".html"],
									slug<>".html"
									],
						True,	
							Nothing
						]
					],
				"Content"->
					content
				},
			Last
			]
		]


WebSiteTemplateApply//ClearAll


WebSiteBuild::nocnt=
	"Can't export content `` to string";
WebSiteTemplateApply[
	root:_String?DirectoryQ|{__String?DirectoryQ},
	content:_String|_File|None,
	templates:{__String}|_String,
	info:_Association:<||>
	]:=
	If[AssociationQ@$ContentStack,
		With[{
			fils=
				Select[
					FileNameJoin@{
						First@Flatten@List@root,
						#}&/@Flatten@List@templates,
					FileExistsQ
					],
			args=
				If[MemberQ[Lookup[#,"Templates",{}],"article.html"],
					Merge[{
						#,
						"Categories"->{"misc"}
						},
						Replace[{
							{l_List,l2_List}:>
								DeleteDuplicates@Flatten@{l,l2},
							{e_}:>e
							}]
						],
					#
					]&@
				Merge[(* Collect the arguments to pass to the template *)
					{
						(* A function for choosing objects by the template used *)
						"SelectObjects"->
							Function[
								With[{type=ToLowerCase[#]<>".html"},
									Select[
										Values@
											$ContentStack[[All,"Attributes"]],
										MemberQ[#["Templates"],type]&
										]
									]
								],
						(* A function for getting object attributes by file name *)
						"ContentData"->
							Function[
								Fold[
									Lookup[#,#2,<||>]&,
									$ContentStack,
									{#,"Attributes"}
									]
								],
						(* The pages *)
						"Pages":>
							Select[
								Values@
									$ContentStack[[All,"Attributes"]],
								MemberQ[#["Templates"],"page.html"]&
								],
						(* The articles *)
						"Articles":>
							Select[
								Values@
									$ContentStack[[All,"Attributes"]],
								MemberQ[#["Templates"],"article.html"]&
								],
						(* The archives *)
						"Archives":>
							Reverse@
								GatherBy[
									Values@
										$ContentStack[[All,"Attributes"]],
									#["Date"]&
									],
						info,
						(* Include extracted attributes *)
						Lookup[
							Lookup[$ContentStack,content,<||>],
							"Attributes",
							{}
							]
						},
					Last
					]
				},
				(* Allows for custom slugs *)
				Lookup[
					Fold[
						Lookup[#,#2,<||>]&,
						$ContentStack,
						{content,"Attributes"}
						],
					"Slug",
					Automatic
					]->
					Fold[
						WebSiteXMLTemplateApply[
							root,
							#2,
							WebSiteTemplateGatherArgs[
								#,
								If[#=!=None,
									$ContentStack[content,"Attributes"],
									args
									]
								]
							]&,
						If[content=!=None,
							$ContentStack[content,"Content"],
							None
							],
						fils
						]
				],
		Message[WebSiteBuild::nost];
		$Failed
		]


WebSiteTemplateExport[
	failinput_,
	fout_,
	root_,
	content_,
	templates_,
	config_
	]:=	
	Replace[
		WebSiteTemplateApply[
			root,
			content,
			templates,
			config
			],
		{
			(f_->html_String):>
				Export[
					Replace[f,{
						Automatic:>fout,
						s_String:>
							FileNameJoin@
								Append[
									Most@FileNameSplit[fout],
									FileBaseName@s<>".html"
									]
						}],
					html,
					"Text"],
			e_:>
				(Print[e];Message[WebSiteBuild::genfl,failinput];$Failed)
			}
		];


WebSiteImportMeta[xml:(XMLObject[___][___]|XMLElement["html",___])]:=
	WebSiteImportMeta/@
		Cases[xml,
			XMLElement["meta",__],
			\[Infinity]
			];
WebSiteImportMeta[
	XMLElement["meta",info_,_]
	]:=
	Replace[
		Lookup[
			info,
			{"name","content"},
			Nothing
			],{
		{n_,c_}:>
			n->
				If[MemberQ[$WebSiteAggregationTypes,n]||
						StringMatchQ[c,Repeated[Except[","]..~~","]],
					StringTrim@StringSplit[c,","],
					c
					],
		_->Nothing
		}];


WebSiteBuild::nost="$ContentStack not initialzed";
WebSiteExtractFileData[content_,config_]:=
	If[AssociationQ@$ContentStack,
		With[{
			fileContent=
				Replace[content,{
					(_File|_String)?FileExistsQ:>
						Switch[FileExtension[content],
							"md",
								MarkdownToXML[Import[content,"Text"]],
							"html"|"xml",
								Import[content,{"HTML","XMLObject"}]
							]
					}]
			},
			With[{
				args=
					Merge[
						{
							config,
							Replace[fileContent,{
								(XMLObject[___][___]|XMLElement["html",___]):>
									WebSiteImportMeta[fileContent],
								_->{}
								}]
							},
						Last
						]
				},
				If[content=!=None,
					$ContentStack[content]=
						<|
							"Attributes"->
								WebSiteTemplateGatherArgs[fileContent,args]
							|>;
					$ContentStack[content,"Content"]=
						WebSiteTemplatePreProcess[fileContent,
							$ContentStack[content,"Attributes"]
							];
					];
				]
			],
		Message[WebSiteBuild::nost];
		$Failed
		];


WebSiteExtractPageData[rootDir_,files_,config_]:=
	Block[{
		extractfile
		},
		Monitor[
			With[{
				fname=
					Replace[#,
						f:Except[_String|_File]:>
							ExpandFileName@First[f]
						],
				templates=
					Flatten@List@
					Replace[#,{
						r:Except[_String|_File]:>
							Last[r],
						_->"base.html"
						}]
				},
				extractfile=fname;
				WebSiteExtractFileData[fname,
					Merge[
						{
							config,
							"Templates"->
								templates,
							"FilePath"->
								WebSiteBuildFilePath[fname,rootDir]
							},
						Last
						]
					]
				]&/@files,
			Internal`LoadingPanel@
				TemplateApply[
					"Extracting data from ``",
					extractfile
					]
			]
		];


WebSiteGenerateAggregationPages//ClearAll;


$WebSiteAggregationTypes=
	{
			"Authors",
			"Categories",
			"Tags"
			};


$WebSiteGenerateAggregationPages=
	AssociationMap[
		With[{
			singular=
				ToLowerCase@Switch[#,
					"Categories",
						"Category",
					_,
						StringTrim[#,"s"]
					],
			plural=ToLowerCase[#]
			},
			<|
				"AggregationTemplates"->plural<>".html",
				"AggregationFile"->plural<>".html",
				"Templates"->singular<>".html",
				"File"->Function@{plural,ToLowerCase[#]<>".html"}
				|>
			]&,
		$WebSiteAggregationTypes
		];
WebSiteGenerateAggregationPages[dir_,aggpages_:Automatic,outDir_,theme_,config_]:=
	With[
		{
			longDir=ExpandFileName@dir,
			thm=WebSiteFindTheme[dir,theme]
			},
		Block[{
			aggbit,
			outfile
			},
			Monitor[
				KeyValueMap[(*Map over aggregation types and templates*)
					With[{
						aggthing=#,
						aggdata=#2,
						aggsingular=
							Switch[#,
								"Categories",
									"Category",
								_,
									StringTrim[#,"s"]
								]
						},
						Block[{
							(* Files to be collected and passed to combined aggregation *)
							$aggregationFiles=<||>,
							(*Collect type name and templates*)
							agglist=
								KeySort@Map[Flatten@*List]@
									GroupBy[First->Last]@
										Flatten[
											Thread@*Reverse/@
												Normal@
													DeleteCases[
														Lookup[
															Lookup[#,"Attributes",<||>],
															aggthing,
															{}
															]&/@$ContentStack,
														{}
														]
											]
							(*Gather elements in the content stack  by type in the aggregation*)
							},
							KeyValueMap[
								(*Map over aggregated elements, e.g., over each tag or category*)
								With[{
									fout=
										(*The file to export the aggregation file to*)
										WebSiteBuildSlug@
											FileNameJoin@Flatten@{
												outDir,
												aggdata["File"]@#
												},
									templates=
										(*The template file to use*)
										Flatten@List@
											aggdata["Templates"]
									},
									$aggregationFiles[#]=
										<|
											aggsingular->#,
											"File"->fout,
											"Articles"->#2,
											"URL"->
												WebSiteBuildURL@
													FileNameDrop[fout,FileNameDepth@outDir]
											|>;
									aggbit=ToLowerCase[aggthing<>"/"<>#];
									(* Make sure directory exists *)
									If[!DirectoryQ@DirectoryName@fout,
										CreateDirectory@DirectoryName@fout
										];
									(* 
								Export aggregation file, e.g. tags/mathematica.html passing the 
								list of file URLs as the aggregation name, e.g. Tags
								*)
									WebSiteTemplateExport[
										aggbit,
										fout,
										{FileNameJoin@{thm,"templates"},longDir},
										None,
										templates,
										Merge[
											{
												config,
												aggsingular->#,
												"Articles":>
													Lookup[
														Lookup[$ContentStack,#2,<||>],
														"Attributes",
														<||>
														],
												"URL"->
													WebSiteBuildURL@
														FileNameDrop[fout,FileNameDepth@outDir]
												},
											Last
											]
										];
									aggbit=.;
									]&,
								agglist
								];
							If[(* If there's a overall aggregation to use, e.g. all tags or categories*)
								AllTrue[{"AggregationFile","AggregationTemplates"},
									KeyMemberQ[aggdata,#]&
									],
								With[{
									fout=
										WebSiteBuildSlug@
										FileNameJoin@Flatten@{
											outDir,
											aggdata["AggregationFile"]
											},
									templates=
										Flatten@List@
											aggdata["AggregationTemplates"]
									},
									aggbit=ToLowerCase@aggthing;
									If[!DirectoryQ@DirectoryName@fout,
										CreateDirectory@DirectoryName@fout
										];
									WebSiteTemplateExport[
										aggbit,
										fout,
										{FileNameJoin@{thm,"templates"},longDir},
										None,
										templates,
										Merge[
											{
												config,
												aggthing->
													Values@$aggregationFiles,
												"URL"->
													WebSiteBuildURL@
														FileNameDrop[fout,FileNameDepth@outDir]
												},
											Last
											]
										];
									aggbit=.;
									]
								]
							]
						]&,
					Replace[aggpages,Automatic:>$WebSiteGenerateAggregationPages]
					];,
				Internal`LoadingPanel@
					TemplateApply[
						"Aggregating ``",
						{
							aggbit
							}
						]
				]
			];
		];


WebSiteGenerateIndexPage//ClearAll


WebSiteGenerateIndexPage[dir_,outDir_,theme_,config_]:=
	With[
		{
			longDir=ExpandFileName@dir,
			thm=WebSiteFindTheme[dir,theme]
			},
			Monitor[
				WebSiteTemplateExport[
					"index",
					FileNameJoin@{outDir,"index.html"},
					{FileNameJoin@{thm,"templates"},longDir},
					None,
					{"index.html"},
					Merge[
						{
							config,
							"URL"->"index.html"
							},
						Last
						]
					];,
				Internal`LoadingPanel@"Generating index page"
				];
		];


WebSiteGenerateContent//ClearAll


WebSiteBuild::genfl="Failed to generate HTML for file ``";


WebSiteGenerateContent[dir_,files_,outDir_,theme_,config_]:=
	With[{
			longDir=ExpandFileName@dir,
			thm=WebSiteFindTheme[dir,theme]
			},
		Block[
			{
				genfile,
				outfile
				},
			Monitor[
				With[
					{
						fname=
							(* In case the file had a path already *)
							ExpandFileName@
								Replace[#,Except[_String|_File]:>First[#]],
						path=
							(* Use path if provided, else base.html *)
							Flatten@List@
								Replace[#,
									{
										Except[_String|_File]:>Last[#],
										_:>
											WebSiteBuildGetTemplates[
												ExpandFileName@
													Replace[#,Except[_String|_File]:>First[#]],
												longDir
												]
										}
									]
							},
					With[
						{
							fout=
								Replace[
									Fold[
										Lookup[#,#2,<||>]&,
										$ContentStack,
										{fname,"Attributes","URL"}
										],{
										u_String:>
											FileNameJoin@
												Flatten@{
													outDir,
													URLParse[u,"Path"]
													},
										_:>
											Function[
												If[FileExtension[#]=!="html",
													DirectoryName[#]<>
														FileBaseName[#]<>".html",
													#
													]
												]@
												FileNameJoin@{
													outDir,
													WebSiteBuildSlug@
														Lookup[
															Lookup[
																Lookup[$ContentStack,fname,<||>],
																"Attributes",
																<||>
																],
															"FilePath",
															WebSiteBuildFilePath[fname,outDir]
															]
													}
									}]
							},
						genfile=fname;
						If[!DirectoryQ@DirectoryName@fout,
							CreateDirectory@DirectoryName@fout
							];
						WebSiteTemplateExport[
							genfile,
							fout,
							{FileNameJoin@{thm,"templates"},longDir},
							fname,
							path,
							Merge[
								{
									config,
									"URL"->
										WebSiteBuildURL@
											FileNameDrop[fout,FileNameDepth@outDir]
									},
								Last
								]
							];
						outfile=.;
						]
					]&/@files,
				Internal`LoadingPanel@
					TemplateApply[
						"Exporting ``",
						{
							genfile
							}
						]
				]
			];
		];


WebSiteFindTheme[dir_,theme_]:=
	SelectFirst[
		{theme,
			FileNameJoin@{dir,"themes",theme},
			PackageFilePath["Resources","Themes",theme]
			},
		DirectoryQ
		]


WebSiteCopyTheme[dir_,outDir_,theme_]:=
	With[{
		thm=
			FileNameJoin@{
				WebSiteFindTheme[dir,theme],
				"static"
				}
		},
		Quiet@CreateDirectory[FileNameJoin@{outDir,"theme"}];
		With[{fils=Select[Not@*DirectoryQ]@FileNames["*",thm,\[Infinity]]},
			Block[{
				copyfile,
				newfile
				},
				Monitor[
					With[{
						newf=
							FileNameJoin@{outDir,"theme",
								FileNameDrop[#,FileNameDepth[thm]]
								}
						},
						If[!(FileExistsQ[newf]&&FileHash[#]==FileHash[newf]),
							copyfile=#;
							newfile=newf;
							If[!DirectoryQ@DirectoryName@newf,
								CreateDirectory[DirectoryName@newf,
									CreateIntermediateDirectories->True
									]
								];
							CopyFile[#,newf,OverwriteTarget->True]
							];
						copyfile=.;
						newfile=.;
						]&/@fils,
					Internal`LoadingPanel@
						If[AllTrue[{copyfile,newfile},StringQ],
							TemplateApply["Copying `` to ``",
								{
									copyfile,
									newfile
									}
								],
							TemplateApply[
								"Copying theme ``",
								thm
								]
							]
					]
				]
			];
		FileNameJoin@{outDir,"theme"}
		]


WebSiteCopyContent[dir_,outDir_,sel_:Automatic]:=
	With[{
		selPat=
			Replace[sel,
				Automatic:>Except["posts"|"pages"]
				],
		contDir=
			FileNameJoin@{dir,"content"}
		},
		With[{
			fils=
				Select[
					MatchQ[FileNameTake[#,{FileNameDepth[contDir]+1}],selPat]&
					]@
					Select[Not@*DirectoryQ]@
						FileNames["*",contDir,\[Infinity]]
			},
			Block[{
				copyfile,
				newfile
				},
				Monitor[
					With[{
						newf=
							FileNameJoin@{outDir,
								FileNameDrop[#,FileNameDepth[contDir]]
								}
							},
						If[!FileExistsQ[newf]||FileHash[#]=!=FileHash[newf],
							If[!DirectoryQ@DirectoryName@newf,
								CreateDirectory[DirectoryName@newf,
									CreateIntermediateDirectories->True
									]
								];
							CopyFile[#,newf,OverwriteTarget->True]
							]
						]&/@fils,
					Internal`LoadingPanel@
						If[AllTrue[{copyfile,newfile},StringQ],
							TemplateApply["Copying `` to ``",
								{
									copyfile,
									newfile
									}
								],
							TemplateApply[
								"Copying content from ``",
								contDir
								]
							]
					]
				]
			];
		outDir
		]


WebSiteBuild::ndcnt="Can't generate `` without generating content first";


Options[WebSiteBuild]=
{
	"CopyContent"->True,
	"CopyTheme"->True,
	"GenerateContent"->True,
	"GenerateIndex"->Automatic,
	"GenerateAggregations"->Automatic,
	"Configuration"->Automatic,
	"OutputDirectory"->Automatic,
	"DefaultTheme"->"minimal",
	"AutoDeploy"->Automatic,
	"DeployOptions"->Automatic
	};
WebSiteBuild[
	dir_String?DirectoryQ,
	files:
		{(_String?FileExistsQ|((_String?FileExistsQ)->_List))..}|
			s_?(StringPattern`StringPatternQ)|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		outDir=
			Replace[OptionValue["OutputDirectory"],
				Automatic:>
					FileNameJoin@{dir,"output"}
				],
		fileNames=
			Replace[files,{
				Automatic:>
					Join@@
						MapThread[
							Thread[
								FileNames["*.html"|"*.md",
									FileNameJoin@{dir,"content",#},
									\[Infinity]
									]->#2
								]&,
							{
								{"posts","pages"},
								{"article.html","page.html"}
								}
							]
				}],
		config=
			Replace[
				Replace[OptionValue["Configuration"],
					Automatic:>
						If[FileExistsQ@FileNameJoin@{dir,"SiteConfig.m"},
							FileNameJoin@{dir,"SiteConfig.m"},
							FileNameJoin@{dir,"SiteConfig.wl"}
							]
					],{
					f_String?FileExistsQ:>
						Replace[Import[f],{o_?OptionQ:>Association[o],_-><||>}],
					o_?OptionQ:>Association[o],
					_-><||>
				}]
			},
		If[!DirectoryQ[outDir],
			CreateDirectory@outDir
			];
		If[OptionValue["CopyTheme"],
			WebSiteCopyTheme[dir,outDir,
				Lookup[config,"Theme",OptionValue["DefaultTheme"]]
				]
			];
		Replace[OptionValue["CopyContent"],{
			True|Automatic:>
				WebSiteCopyContent[dir,outDir,Automatic],
			p:Except[False|None]:>
				WebSiteCopyContent[dir,outDir,p]
			}];
		Block[{
			$ContentStack=<||>,
			genCont:=
				Replace[OptionValue["GenerateContent"],
					Automatic:>
						Lookup[config,"GenerateContent",Automatic]
					],
			genAggs:=
				Replace[OptionValue["GenerateAggregations"],
					Automatic:>
						Lookup[config,"GenerateAggregations",genCont]
					],
			genInd:=
				Replace[OptionValue["GenerateIndex"],
					Automatic:>
						Lookup[config,"GenerateIndex",genCont]
					],
			newconf=
				KeyDrop[config,{"GenerateContent","GenerateAggregations","GenerateIndex"}]
			},
			If[AnyTrue[{genCont,genAggs,genInd},TrueQ],
				WebSiteExtractPageData[ExpandFileName@dir,fileNames,newconf]
				];
			If[genCont,
				WebSiteGenerateContent[
					dir,fileNames,outDir,
					Lookup[config,"Theme",OptionValue["DefaultTheme"]],
					Join[
						<|
							"SiteDirectory"->dir,
							"OutputDirectory"->outDir
							|>,
						newconf
						]
					]
				];
			If[genAggs,
				WebSiteGenerateAggregationPages[
					dir,outDir,
					Lookup[config,"Theme",OptionValue["DefaultTheme"]],
					newconf
					];
				];
			If[genInd,
				WebSiteGenerateIndexPage[
					dir,outDir,
					Lookup[config,"Theme",OptionValue["DefaultTheme"]],
					newconf
					];
				];
			];
		If[TrueQ[OptionValue["AutoDeploy"]]||
			OptionValue["AutoDeploy"]===Automatic&&
				OptionQ@OptionValue["DeployOptions"],
			WebSiteDeploy[outDir,
				Lookup[config,"SiteURL",
					Replace[FileBaseName[dir],
						"output":>
							FileBaseName@DirectoryName[dir]
						]
					],
				Replace[
					Replace[OptionValue["DeployOptions"],
						Automatic:>Lookup[config,"DeployOptions",{}]
						],
					Except[_?OptionQ]->{}
					]
				],
			outDir
			]
		];


$WebFileFormats=
	"html"|"css"|"js"|
	"png"|"jpg"|"gif"|
	"woff"|"tff"|"eot"|"svg";


Options[WebSiteDeploy]=
	Join[
		{
			FileNameForms->"*."~~$WebFileFormats,
			"ExtraFileNameForms"->{},
			Select->(True&),
			CloudConnect->False,
			"LastDeployment"->Automatic,
			Permissions->"Public"
			},
		Options[CloudObject]
		];
WebSiteDeploy[
	outDir_String?DirectoryQ,
	uri:_String|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		trueDir=
			If[
				FileBaseName[outDir]==="output"&&
					FileExistsQ@
						FileNameJoin@{
							DirectoryName[outDir],
							"SiteConfig.wl"
							},
				DirectoryName[outDir],
				outDir
				]
		},
	With[{
			info=
				If[FileExistsQ[FileNameJoin@{trueDir,"DeploymentInfo.m"}],
					Import[FileNameJoin@{trueDir,"DeploymentInfo.m"}],
					{}
					]
			},
			Export[FileNameJoin@{trueDir,"DeploymentInfo.m"},
				KeyDrop[
					Association@
						Flatten@{
							Normal@info,
							ops,
							"LastDeployment"->Now
							},
					{FileNameForms,"ExtraFileNameForms"}
					]
				];
	With[{
		select=OptionValue[Select],
		last=
			Replace[OptionValue["LastDeployment"],
				Automatic:>Lookup[info,"LastDeployment",None]
				]
		},
		KeyChainConnect[OptionValue[CloudConnect]];
		Block[{file},
			Monitor[
				Map[
					Function[
						file=#;
						With[{url=
							URLBuild@Flatten@{
									Replace[uri,
										Automatic:>
											FileBaseName[trueDir]
										],
									FileNameSplit@
										FileNameDrop[
											#,
											FileNameDepth[outDir]
											]
									}
							},
							If[StringEndsQ[url,"/index.html"],
								CopyFile[
										#,
										CloudObject[
											StringTrim[url,"/index.html"]<>"/main.html",
											FilterRules[
												Flatten@{ops,Options[WebSiteDeploy]},
												Options[CloudObject]
												]
											]
										]
								];
							Most@
								CopyFile[
									#,
									CloudObject[
										url,
										FilterRules[
											Flatten@{ops,Options[WebSiteDeploy]},
											Options[CloudObject]
											]
										]
									]
							]
						],
					Select[
						!DirectoryQ[#]&&
							(!DateObjectQ[last]||Quiet[FileDate[#]>last,Greater::nordol])&&
							select[#]&
							]@
						SortBy[FileBaseName[#]==="index"&]@
						FileNames[
							Replace[
								Alternatives@@List@{
									OptionValue[FileNameForms],
									OptionValue["ExtraFileNameForms"]
									},
								All->"*"
								],
							outDir,
							\[Infinity]]
					],
				Internal`LoadingPanel[
					TemplateApply["Deploying ``",file]
					]
				]
			]
		]
		]
		];


End[];



