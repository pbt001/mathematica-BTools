(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



(* ::Subsection:: *)
(*SetUp*)



guideRefBox//ClearAll


guideRefBox[name_String->f_String,styling_:Automatic]:=
	Which[
		styling===Automatic&&StringContainsQ[f,"/guide/"],
			Cell[BoxData@guideRefBox[name->f,"GuideMoreAbout"],
			  "GuideMoreAbout"],
		styling===Automatic&&StringContainsQ[f,"/tutorial/"],
			Cell[BoxData@guideRefBox[name->f,"RelatedTutorials"],
			  "RelatedTutorials"],
		True,
			Cell[
				BoxData@
					TemplateBox[{
						Cell[TextData[Last@StringSplit[name,"`"]]],
								Which[
									StringMatchQ[f,"\"*"],
										pacletLinkBuild[{"format",f}],
									StringMatchQ[f,"paclet:*"],
										f,
									True,
										pacletLinkBuild@f
									]
							},
				   "RefLink",
				   BaseStyle->Replace[styling,Automatic:>"InlineFunctionSans"]]
				]
		];
guideGuideRefBox[n_,g_]:=
	TemplateBox[{
		Cell[Replace[n,{None->"...",_:>TextData[n<>" \[RightGuillemet]"]}]],
			If[StringContainsQ[g,"/guide/"],
				"paclet:"<>StringTrim[g,"paclet:"],
				pacletLinkBuild[g,"guide"]
				]},
	 	 "OrangeLink",
		  BaseStyle->"GuideFunctionsSubsection"
		];
guideRefBox[s_String,styling_:"InlineFunctionSans"]:=
	guideRefBox[s->s,styling];


guideSubsection[Delimiter]=
	guideFunctionCell[Delimiter,___];
guideSubsection[
	name:(_String->_String)|_String|None,
	fs_
	]:=
	Cell@
		CellGroupData[Flatten@{
			Replace[name,{
				None->Nothing,
				e_:>
					guideSubsectionHead@e
				}],
			guideFunctionCell[#,name]&/@fs
			}];
guideSubsection[name_->fs_]:=
	guideSubsection[name,fs];


guideSubsectionHead[name_]:=
	Cell[
		Replace[name,{
			(n_->g_):>
				 BoxData@guideGuideRefBox[n,g]
			}],
		"GuideFunctionsSubsection"
		];


guideFunctionCell//ClearAll


guideFunctionCell[functions:{(_String|_Rule)..},name_:None]:=
	Cell[TextData[Flatten@{
		If[Length@#>1,
			Riffle[#,
				{{"\[NonBreakingSpace]",StyleBox["\[MediumSpace]\[FilledVerySmallSquare]\[MediumSpace]", "InlineSeparator"]," "}}
				],
			#]&[
				Append[
					Replace[
						functions,{
							f:_Rule|_String?(StringMatchQ[(WordCharacter|"$")..]):>
								guideRefBox[f]
						},
						1],
					Replace[name,{
						(n_->g_):>
							Cell[BoxData@guideGuideRefBox[None,g]],
						_->Nothing
						}]
					]
				]
		}],
		"InlineGuideFunctionListing"
		];


guideFunctionCell[Column[l_],___]:=
	Cell[
		CellGroupData@
			Map[guideFunctionCell,l]
		]


guideFunctionCell[
	header_String->(functions:_List|Column[_List,___]),
	___
	]:=
	Cell@
		CellGroupData[
			Flatten@{
				Cell[header,"GuideFunctionsSubsection"],
				guideFunctionCell@functions
				}
			];


guideFunctionCell[functions_List->(description:_String|_Cell),___]:=
	Cell[
		TextData@Flatten@{
			Riffle[guideRefBox/@Replace[functions,_Rule:>{functions}],", "],
			StyleBox[" \[LongDash] ", "GuideEmDash"],
			description
			},
		"GuideText"];
guideFunctionCell[f_String->p_String,___]:=
	Cell[TextData@{guideRefBox[f->p]},"GuideText"];
guideFunctionCell[text_String,___]:=
	Cell[text,"GuideText"];
guideFunctionCell[Delimiter,___]:=
	Cell["\t", "GuideDelimiter"];
(*guideFunctionCell[t___]:=
	Cell[FE`makePlainText[Cell[TextData@{t}]],"GuideText"]*)


iGuideSubsections[subsections_]:=
	Cell[CellGroupData[
		guideSubsection/@
			subsections
		]];


iGuideMain[title_,abstract_]:=
	Cell[CellGroupData@Flatten@{
		Cell[title,"GuideTitle"],
		Cell[#,"GuideAbstract"]&/@abstract,
		Cell["\t", "GuideDelimiterSubsection"]
		}]


$GuideAnchorTitle="GUIDE"


iGuideAnchorBar[name_,fs_,relatedGuides_]:=
	anchorBarCell[
		{
			$GuideAnchorTitle,
			docTypeColor["GUIDE"]
			},
		Replace[generateSymRefs[fs],{
			l:{__}:>
				{"Functions",l,"GuideFunction"},
			_:>Sequence@@{}
			}],
			Replace[generateGuideRefs[relatedGuides],{
				l:{__}:>
					{
						"Related Guides",
						l,
						"MoreAbout"
						},
				_:>Sequence@@{}
				}],
			Replace[generateUrlRefs[name],{
				l:{__}:>
					{ "URL",l,"URLMenu"},
				_:>Sequence@@{}
				}]
		];


iGuideRelatedSection[guides_,tuts_,links_]:=
	If[Length@Flatten@{guides,tuts,links}>0,
		Cell[CellGroupData@Flatten@{
			If[ListQ@guides&&Length@guides>0,
				Cell[CellGroupData@Flatten@{
					Cell["Related Guides", "GuideMoreAboutSection",
			 			System`WholeCellGroupOpener->True],
			 	 Cell[BoxData@guideRefBox[#,"GuideMoreAbout"],
			 	 	"GuideMoreAbout"]&/@guides
			 		}],
			 	Nothing
			 	],
			If[ListQ@tuts&&Length@tuts>0,
				Cell[CellGroupData@Flatten@{
					Cell["Related Tutorials", "GuideTutorialsSection",
			 			System`WholeCellGroupOpener->True],
			 	 Cell[BoxData@guideRefBox[#,"RelatedTutorials"],
			 	 	"RelatedTutorials"]&/@tuts
			 		}],
			 	Nothing
			 	],
			If[ListQ@links&&Length@links>0,
				Cell[CellGroupData@Flatten@{
					Cell["Related Links", "GuideRelatedLinksSection",
			 			System`WholeCellGroupOpener->True],
			 	 Cell[
						TextData@
							Cell[
								BoxData@
									TemplateBox[{First@#, Last@#},
								  	"WebLink",
									  BaseStyle->{"RelatedLinks"}
										]
								],
						"RelatedLinks"
						]&/@links
			 		}],
			 	Nothing
			 	]
			 }],
	 	Nothing
	 	];


guideAutoSubsections[types_]:=
	Riffle[
		KeyValueMap[
			Replace[#,
				Except["Inert"]->#<>"s"
				]->List@#2&,
			types
			],
		Delimiter
		]


guideAutoAbstractContextName[namePattern_]:=
	If[StringEndsQ[namePattern,"`"],
		"in the "<>StringTrim[namePattern,"`"]<>" context",
		"matching "<>namePattern
		]


guideAutoAbstract[inwhat_,names_,types_]:=
	StringRiffle[
		Flatten@{
			Switch[Length@names,
				0,
					TemplateApply[
						"There are no symbols ``",
						inwhat
						],
				1,
					TemplateApply[
						"There is one symbol ``",
						inwhat
						],
				_,
					TemplateApply[
						"There are `` symbols ``",
						{
							Length@names,
							inwhat
							}
						]
				],
			KeyValueMap[
				TemplateApply[
					"`` ``",
					{
						Length@#2,
						If[Length@#2>1,
							"are "<>
								ToLowerCase@
									Replace[#,
										Except["Inert"]->#<>"s"
										],
							"is "<>
								ToLowerCase@
									Replace[#,
										Except["Inert"]->
											If[StringMatchQ[#,("A"|"E"|"I"|"O"|"U")~~__],
												"an",
												"a"
												]<>" "<>#
										]
							]
						}]&,
				types
				]
			},
		"\n"]


iGuideMetadata[guideName_,guideLink_,abstract_,ops___]:=
	docMetadata@{
		ops,
		"Summary"->First@Flatten@abstract,
		"Keywords"->guideName,
		"Title"->guideName,
		"WindowTitle"->guideName,
		"Type"->"Guide",
		"URI"->StringTrim[pacletLinkBuild[guideLink,"guide"],"paclet:"]
		} 


iDocGenGenerateGuide[guideName_,guideLink_,abstract_,functions_,subsections_,
	related_,tuts_,links_]:=
	Block[{cid=1},
		Notebook[{
			iGuideAnchorBar[guideLink,functions,related],
			iGuideMain[guideName,abstract],
			iGuideSubsections[subsections],
			iGuideRelatedSection[related,tuts,links],
			Cell[" ", "FooterCell"]
			}/.Cell[e___]:>Cell[e,CellID->(cid++)],
			StyleDefinitions->
				Notebook[{
					Cell[
						StyleData[
							StyleDefinitions->
								FrontEnd`FileName[{"Wolfram"},
									"Reference.nb",CharacterEncoding->"UTF-8"]
							]
						],
					Cell[StyleData["Notebook"],
						DockedCells->
							{
								First@
									FrontEndResource["FEExpressions","HelpViewerToolbar"],
								Cell["",
									CellSize->{1,1},
									CellOpen->False,
									CellFrame->{{0,0},{2,0}},
									CellFrameColor->docTypeColor@"GUIDE"
									]
								}
						]
					}],
				TaggingRules->{
					"ColorType"->"GuideColor",
					"Metadata"->
						iGuideMetadata[guideName,guideLink,abstract],
					"NewStyles"->True
					}
			]
		];


Options[GuideNotebook]={
	"Title"->None,
	"Abstract"->None,
	"Functions"->{},
	"Subsections"->{},
	"RelatedGuides"->{},
	"RelatedTutorials"->{},
	"RelatedLinks"->{}
	};
GuideNotebook[ops:OptionsPattern[]]:=
	With[{
		t=Replace[OptionValue@"Title",Except[_String|_Rule]:>"No Title"],
		a=Replace[Flatten@{OptionValue@"Abstract"},
			Except[{(_String|_TextData)..}]:>{"No description..."}],
		f=Replace[OptionValue@"Functions",Except[_List]:>{}],
		s=Replace[OptionValue@"Subsections",Except[_List]:>{}],
		g=
			Replace[
				Replace[OptionValue@"RelatedGuides",
					Except[_List]:>{}],
				{}->{"The Wolfram Language"->"guide/LanguageOverview"}
				],
		rt=Replace[OptionValue@"RelatedTutorials",Except[_List]:>{}],
		l=Replace[OptionValue@"RelatedLinks",Except[_List]:>{}]
		},
		docGenBlock@
			iDocGenGenerateGuide[
				Replace[t,{(n_->_):>n}],
				Replace[t,{
					s_String:>
						StringReplace[s,Except[WordCharacter]->""],
					(_->n_):>
						n
					}],
				a,
				f,
				s,
				g,
				rt,
				l]
		];


(* ::Subsection:: *)
(*Generators*)



(* ::Subsubsection::Closed:: *)
(*DocGenGenerateGuide*)



DocGenGenerateGuide::gfail=
	"Failed to generate guide for ``";


Options[DocGenGenerateGuide]=
	Join[
		Options[GuideNotebook],
		Options[CreateDocument],{
			"PostFunction"->None,
			Monitor->False
			}
		];
DocGenGenerateGuide[ops:OptionsPattern[]]:=
	Replace[OptionValue["PostFunction"],None->Identity]@
		CreateDocument[
			GuideNotebook[FilterRules[Flatten@{ops},Options@GuideNotebook]],
			FilterRules[Flatten@{ops},Options@CreateDocument],
			WindowTitle->
				Replace[Lookup[Flatten@{ops},"Title","No Title"],
					e:Except[_String]:>
						FirstCase[e,_String,"No Title",\[Infinity]]
					]<>" - Guide",
			System`ClosingSaveDialog->False,
			Saveable->False
			];
DocGenGenerateGuide[namePattern_String,ops:OptionsPattern[]]:=
	Block[{
		$DocGenActive=
			If[StringMatchQ[namePattern,"*`"],
				StringTrim[namePattern,"`"],
				$DocGenActive
				]
		},
		With[{names=contextNames[namePattern<>"*"]},
			With[{types=GroupBy[Keys@#,#]&@SymbolDetermineType[names]},
				DocGenGenerateGuide[
					"Title"->
						StringTrim[namePattern,"`"]<>" Symbols"->
							StringReplace[namePattern,Except["$"|WordCharacter]->""],
					"Abstract"->
						guideAutoAbstract[
							guideAutoAbstractContextName[namePattern],
							names,
							types
							],
					"Functions"->
						ToExpression[names,StandardForm,Hold],
					"Subsections"->
						guideAutoSubsections[types],
					ops
					]
				]
			]
		];


DocGenGenerateGuide[nb_NotebookObject,ops:OptionsPattern[]]:=
	Block[{
		monit=TrueQ@OptionValue[Monitor],
		title
		},
		With[{
			scrape=scrapeGuideTemplate@nb
			},
			If[Length@scrape>0,title=Lookup[First@scrape,"Title"]];
			If[monit,
				Function[Null,
					Monitor[#,
						If[StringQ@title,
							Internal`LoadingPanel[
								TemplateApply[
									"Generating guide ``",
									title
									]
								],
							""
							]
						],
					HoldFirst
					],
				Identity
				]@
				Block[{$DocGenLine=0},
					title=Lookup[#,"Title"];
					DocGenGenerateGuide[#,ops]
					]&/@scrape
			]
		]


(* ::Subsubsection::Closed:: *)
(*DocGenSaveGuide*)



saveGuidePages[
	nb:_NotebookObject|{__NotebookObject}|
		_EvaluationNotebook|_InputNotebook|_ButtonNotebook,
	dir_String?DirectoryQ,
	extension:True|False:True,
	ops:OptionsPattern[]
	]:=
	(
		Quiet@CreateDirectory[
			FileNameJoin@{
				dir,
				If[extension,
					Sequence@@{
						"Guides"
						},
					Nothing
					]
				},
			CreateIntermediateDirectories->True
			];
		Map[
			Replace[
				CurrentValue[
					#,
					{TaggingRules,"Metadata","uri"}
					],
				s_String:>
					{
						Export[
							FileNameJoin@{
								dir,
								If[extension,
									Sequence@@{
										"ReferencePages",
										"Guides"
										},
									Nothing
									],
								Last@URLParse[s,"Path"]<>".nb"
								},
							DeleteCases[NotebookGet@#,Visible->_]
							]
						}
				]&,
			Flatten@{nb}
		]
		)


	(
			(
				saveSymbolPages[#,dir,extension,ops];
				NotebookClose[#]
				)&
			)


Options[DocGenSaveGuide]=
	Options[DocGenGenerateGuide];
DocGenSaveGuide[
	guide:_String|None|{__String}|
		_NotebookObject|_EvaluationNotebook|_InputNotebook:None,
	dir_String?DirectoryQ,
	extension:True|False:True,
	ops:OptionsPattern[]
	]:=
	Replace[
		If[guide===None,
			DocGenGenerateGuide[Visible->False,ops],
			DocGenGenerateGuide[guide,Visible->False,ops]
			],{
		nb:_NotebookObject|{__NotebookObject}:>(
			Quiet@CreateDirectory[
				FileNameJoin@{
					dir,
					If[extension,
						"Guides",
						Nothing
						]
					},
				CreateIntermediateDirectories->True
				];
			Map[
				With[{nbObj=#},
					Function[NotebookClose[nbObj];#]@
					Export[
						FileNameJoin@{
							dir,
							If[extension,
								"Guides",
								Nothing
								],
							URLParse[
								CurrentValue[
									#,
									{TaggingRules,"Metadata","uri"}
									],
								"Path"
								][[-1]]<>".nb"
							},
						DeleteCases[NotebookGet@nbObj,Visible->_]
						]
					]&,
				Flatten@{nb}
			]),
		_:>
			(Message[DocGenGenerateGuide::gfail,If[guide=!=None,guide,{ops}]];$Failed)
		}];


(* ::Subsection:: *)
(*Helpers*)



(* ::Subsubsection::Closed:: *)
(*GuideGenButton*)



GuideGenButton=
	Button["Generate SymbolPages",
		With[{c=$Context},
			SelectionMove[EvaluationCell[],All,CellGroup
				AutoScroll->False];
			GenerateSymbolPages@InputNotebook[];
			If[$Context=!=c,End[]];
			SelectionMove[EvaluationCell[],After,Cell];
			],
		Method->"Queued"
		];


(* ::Subsubsection::Closed:: *)
(*GuideTemplate*)



Options[GuideTemplate]=
	{
		"Title"->Automatic,
		"Link"->Automatic,
		"Abstract"->Automatic,
		"Functions"->Automatic,
		"Subsections"->Automatic,
		"RelatedGuides"->Automatic,
		"RelatedTutorials"->Automatic,
		"RelatedLinks"->Automatic
		};
GuideTemplate[s_String, ops:OptionsPattern[]]:=
	Notebook[{
		Cell[CellGroupData[
			Flatten@{
				Replace[OptionValue@"Title",{
					Automatic->
						Cell[s<>" Overview","GuideTitle"],
					t_String:>
						Cell[t,"GuideTitle"],
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"Link",{
					Automatic:>
						Cell[StringReplace[s,Except[WordCharacter]->""],"GuideLink"],
					l_String:>
						Cell[l,"GuideLink"],
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"Abstract",{
					Automatic:>
						Cell[s<>" description...","GuideAbstract"],
					a_String:>
						Cell[a,"GuideAbstract"],
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"Functions",{
					Automatic->{
						Cell["Guide Functions","GuideFunctionSubsection"],
						Cell["","GuideFunction"]
						},
					l:{__String}:>
						Cell[CellGroupData[Flatten@{
							Cell["Guide Functions","GuideFunctionSubsection"],
							Sequence@@
								Map[Cell[#,"GuideFunction"]&,l]
							},Closed]],
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"Subsections",{
					Automatic->{
						Cell["Guide Sections","GuideSubsectionSubsection"],
						Cell["Function - Description","GuideSubsectionItem"],
						Cell["Guide | Link","GuideSubsectionItem"],
						Cell["Function","GuideSubsectionItem"]
						},
					r:{__Rule}:>{
						Cell["Guide Sections","GuideSubsectionSubsection"],
						Map[
							Cell[CellGroupData[Flatten@{
								Cell[
									Replace[First@#,{
										(t_->g_):>
											t<>" | "<>g,
										g_:>
											If[StringContainsQ[g," | "],
												g,
												g<>" |"
												]
										}],"GuideSubsectionItem"],
								Cell[#,"GuideSubsectionItem"]&/@Last@#
								}]]&,
							r
							]
						},
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"RelatedGuides",{
					Automatic->{
						Cell["Related Guide","GuidesSection"],
						Cell["Related Guide Title | RelatedGuide",
							"RelatedGuide"]
						},
					l:{(_String|_Rule)..}:>
						{
							Cell["Related Guide","GuidesSection"],
							Map[
								Cell[
									First@#<>" | "<>
										StringReplace[Last@#,Except[WordCharacter]->""],
									"RelatedGuide"]&,
								Replace[l,
									t_String:>(t->t),
									1]
								]
							},
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"RelatedTutorials",{
					Automatic->{
						Cell["Related Tutorials","TutorialSection"],
						Cell["Related Tutorial Title | RelatedTutorial",
							"RelatedTutorial"]
						},
					l:{(_String|_Rule)..}:>
						{
							Cell["Related Tutorials","TutorialSection"],
							Map[
								Cell[
									First@#<>" | "<>
										StringReplace[Last@#,Except[WordCharacter]->""],
									"RelatedTutorial"]&,
								Replace[l,
									t_String:>(t->t),
									1]
								]
							},
					Except[_List|_Cell]->{}
					}],
				Replace[OptionValue@"RelatedLinks",{
					Automatic->{
						Cell["Related Links","LinksSection"],
						Cell["Related Link Title | RelatedLink","RelatedLink"]
						},
					l:{(_String|_Rule)..}:>
						{
							Cell["Related Tutorials","LinksSection"],
							Map[
								Cell[
									First@#<>" | "<>
										StringReplace[Last@#,Except[WordCharacter]->""],
									"RelatedTutorial"]&,
								Replace[l,
									t_String:>(
										URLBuild[
											ReplacePart[
												URLParse[t],{
												"Scheme"->None,
												"Query"->{}
												}]
											]->t),
									1]
								]
							},
					Except[_List|_Cell]->{}
					}],
				Cell["","SectionSeparator"]
				},
			Open]
			]
		},
		StyleDefinitions->
			With[{p=`Package`$PackageName},
				FrontEnd`FileName[{p},"DocGen.nb"]
				]
		];
GuideTemplate[s:{__String},ops:OptionsPattern[]]:=
	Notebook[Flatten[First@GuideTemplate[#,ops]&/@s],
		StyleDefinitions->
			With[{p=`Package`$PackageName},
				FrontEnd`FileName[{p},"DocGen.nb"]
				]
		];


(* ::Subsubsection::Closed:: *)
(*GuideContextTemplate*)



GuideContextTemplate//Clear


Options[GuideContextTemplate]=
	Options@GuideTemplate;
GuideContextTemplate[pat_String, ops:OptionsPattern[]]:=
	GuideTemplate[pat,
		ops,
		"Title"->pat<>" Context Overview",
		"Functions"->contextNames[pat<>"*"]
		]
GuideContextTemplate[s:{__String}, ops:OptionsPattern[]]:=
	With[{pages=GuideContextTemplate[#, ops]&/@s},
		Notebook[Flatten@pages[[All, 1]],
			pages[[1, 2;;]]
			]
		]


(* ::Subsubsection::Closed:: *)
(*scrapeGuideTemplate*)



scrapeGuideChunk[c:{__Cell}]:=
	docGenBlock[
		With[{
			title=FirstCase[c,Cell[s_,___,"GuideTitle",___]:>s],
			link=FirstCase[c,Cell[l_,___,"GuideLink",___]:>l,None],
			ab=Cases[c,Cell[ab_,___,"GuideAbstract",___]:>ab],
			funcs=Cases[c,Cell[f_,"GuideFunction",___]:>f],
			subsections=Cases[c,Cell[s_,"GuideSubsectionItem",___]:>s],
			guides=Cases[c,Cell[__,"RelatedGuide",___]],
			tuts=Cases[c,Cell[__,"RelatedTutorial",___]],
			links=Cases[c,Cell[__,"RelatedLink",___]]
			},
			{
				"Title"->
					If[link===None,title,title->link],
				"Abstract"->
					ab,
				"Functions"->
					StringTrim/@funcs,
				"Subsections"->
					Replace[
						DeleteCases[
							SplitBy[
								Replace[subsections,{
									s_String?(StringMatchQ["* - *"]):>
										With[{spl=StringSplit[s," - ",2]},
											StringTrim@StringSplit[First@spl,","]->
												Last@spl
											],
									s_String?(StringMatchQ["* |*"]):>
										Sequence@@{
											"- BreakPoint -",
											Rule@@StringSplit[s," |",2]
											},
									"Delimiter"|"----"|"":>
										Delimiter
									},
									1],
								MatchQ[#,"- BreakPoint -"]&
								],
							{"- BreakPoint -"}
							],{
					{Delimiter}->Delimiter,
					{r:(_String->_),e___}:>
						If[MatchQ[StringTrim@Last@r,
								_String?docSymStringPat],
							StringTrim/@r,
							StringTrim@First@r
							]->
							Replace[
								SplitBy[{e},
									MatchQ[_String?docSymStringPat]],
								l:Except[
									_?(AllTrue[#,MatchQ[_String?docSymStringPat]]&)
									]:>
									Sequence@@l,
								1],
					l_List:>
						None->
							Replace[
								SplitBy[l,
									MatchQ[_String?docSymStringPat]],
								l2:Except[
									_?(AllTrue[#,MatchQ[_String?docSymStringPat]]&)
									]:>
									Sequence@@l2,
								1]
					},
					1],
				"RelatedGuides"->
					Replace[First/@guides,{
						s_String:>
							Replace[StringSplit[s," | "],{
								{str_}:>
									str->pacletLinkBuild[str,"guide"],
								{l_,g_}:>
									l->pacletLinkBuild[g,"guide"]
								}],
						_->Nothing
						},
						1],
				"RelatedTutorials"->
					Replace[First/@tuts,{
						s_String:>
							Replace[StringSplit[s," | "],{
								{str_}:>
									str->pacletLinkBuild[str,"tutorial"],
								{l_,g_}:>
									l->pacletLinkBuild[g,"tutorial"]
								}],
						_->Nothing
						},
						1],
				"RelatedLinks"->
					Replace[First/@links,{
						s_String:>
							Replace[StringSplit[s," | "],{
								{str_}:>
									str->str,
								{l_,g_}:>
									l->g
								}],
						_->Nothing
						},
						1],
				WindowTitle->
					Replace[link,Except[_String]->title]
				}
			]
		];
scrapeGuideTemplate[c:{__Cell}]:=
	With[{cells=NotebookTools`FlattenCellGroups@c},
		scrapeGuideChunk@cells[[#]]&/@
			Replace[
				Flatten@Position[cells,Cell[__,"GuideTitle",___]],{
					i:{__}:>
						Span@@@Partition[Riffle[i,Append[Rest@i-1,-1]],2]
				}]
		]


scrapeGuideTemplate[cells:{__CellObject}]:=
	scrapeGuideTemplate[NotebookRead/@cells];
scrapeGuideTemplate[nb_NotebookObject]:=
	scrapeGuideTemplate@
		Replace[NotebookRead@nb,{
			c_Cell:>
				{c},
			c:{__Cell}:>
				c,
			_:>
				Cells@nb
			}];


(* ::Subsection:: *)
(*Usages*)



(* ::Subsubsection::Closed:: *)
(*GenerateMultiPackageOverview*)



DocumentationMultiPackageOverviewNotebook//ClearAll


extractPackageOverviewSections[
	pkgName_->ops_?OptionQ
	]:=
	Module[{syms,guides,tuts},
		{syms,guides,tuts}=
			Lookup[
				Flatten@{ops},
				{"Symbols","Guides","Tutorials"},
				{}
				];
		syms=
			Replace[syms,
				{
					(r_->s_String):>
						(
							r->
								If[!StringContainsQ[s,"/"],
									URLBuild@{pkgName,"ref",s}
									]
							),
					s_String?FileExistsQ:>
						(
							FileBaseName[s]->
								URLBuild@{pkgName,"ref",FileBaseName[s]}
							),
					s_String:>
						If[StringContainsQ[s,"/"],
							URLParse[s,"Path"][[-1]]->
								s,
							s->
								URLBuild@{pkgName,"ref",s}
							],
					_->Nothing
					},
				1];
		guides=
			Replace[guides,
				{
					(r_->s_String):>
						(r->
							If[!StringContainsQ[s,"/"],
								URLBuild@{pkgName,"guide",s}
								]
							),
					s_String?FileExistsQ:>
						Rule@@Fold[
							Lookup,
							List@@
								Rest@Import[s],
							{
								TaggingRules,
								"Metadata",
								{"title","uri"}
								}
							],
					s_String:>
						If[StringContainsQ[s,"/"],
							URLParse[s,"Path"][[-1]]->
								s,
							s->URLBuild@{pkgName,"guide",s}
							],
					_->Nothing
					},
				1
				];
		tuts=
			Replace[tuts,
				{
					(r_->s_String):>
						(r->
							If[!StringContainsQ[s,"/"],
								URLBuild@{pkgName,"tutorial",s}
								]
							),
					s_String?FileExistsQ:>
						Rule@@Fold[
							Lookup,
							List@@
								Rest@Import[s],
							{
								TaggingRules,
								"Metadata",
								{"title","uri"}
								}
							],
					s_String:>
						If[StringContainsQ[s,"/"],
							URLParse[s,"Path"][[-1]]->
								s,
							s->URLBuild@{pkgName,"tutorial",s}
							],
					_->Nothing
					},
				1
				];
		pkgName->{syms,guides,tuts}
		]


formatPackageOverview//ClearAll


formatPackageOverview[
	pkgName_->
		{syms_,guides_,tuts_}
	]:=
	pkgName->{
		"`name` has `symbols`, `guides`, `tutorials`"
			~TemplateApply~
			<|
				"name"->pkgName,
				"symbols"->
					Replace[Length[syms],{
						0->"no symbol pages",
						1->"one symbol page",
						n_:>ToString[n]<>" symbol pages"
						}],
				"guides"->
					Replace[Length[guides],{
						0->"no guides",
						1->"one guide",
						n_:>ToString[n]<>" guides"
						}],
				"tutorials"->
					Replace[Length[tuts],{
						0->"no tutorials",
						1->"one tutorial",
						n_:>ToString[n]<>" tutorials"
						}]
				|>,
			If[Length[syms]>0,
				"Symbols"->
					If[Length[syms]>15,
						Append["..."],Identity]@
							Take[syms,UpTo[15]
						],
				Nothing
				],
			If[Length[guides]>0,
				"Guides"->Column@Take[guides,UpTo[5]],
				Nothing
				],
			If[Length[tuts]>0,
				"Tutorials"->Column@Take[tuts,UpTo[5]],
				Nothing
				]
			}


Options[DocumentationMultiPackageOverviewNotebook]=
	Options[GuideNotebook]
DocumentationMultiPackageOverviewNotebook[
	pkgs:{__Rule},
	ops:OptionsPattern[]
	]:=
	Block[{
		$DocGenActive="System",
		$GuideAnchorTitle="Documentation Overview",
		data=formatPackageOverview@*extractPackageOverviewSections/@pkgs,
		relguides
		},
		relguides=
			Map[
				Replace[
					Map[Last]@
					Select[
						First@
							Lookup[Cases[_Rule]@#[[2]],"Guides",Column@{}],
						With[{p=#[[1]]},
							StringMatchQ[
								FileBaseName[Last@#],
								p|p<>"Overview"
								]&
							]
						],
					{
						{l_,___}:>(#[[1]]->l),
						_->Nothing
						}
					]&,
				data
				];
		data=
			Replace[data,
				(k_String->v_):>
					With[{g=Lookup[relguides,k]},
						If[StringQ[g],
							(k->g)->v,
							k->v
							]
						],
				1
				];
		GuideNotebook[
			"Subsections"->
				Flatten@Join[
					Replace[OptionValue["Subsections"],{
						{r__}:>
							{r,Delimiter},
						Except[_List]->{}
						}],
					Riffle[
						data,
						Delimiter
						]
					],
			ops,
			"Title"->"Documentation Overview",
			"Abstract"->
				"This is a documentation overview for ``"~TemplateApply~
					StringJoin@
						Switch[Length[pkgs],
							1,
								First/@pkgs,
							2,
								Riffle[First/@pkgs," and "],
							_,
								Insert[
									Riffle[First/@pkgs,", "],
									" and ",
									-2
									]
							],
			"RelatedGuides"->
				Join[
					Replace[Except[_List]->{}]@OptionValue["Subsections"],
					relguides
					]
			]
		];


extractDirectoryDocs[d_]:=
	Which[
		DirectoryQ@FileNameJoin@{d,"Documentation"}&&
			Length@FileNames[
				"ReferencePages"|"Guides"|"Tutorials",
				d,
				3
				]>0,
			Append[
				extractDirectoryDocs/@
					Select[FileNames["*",d],DirectoryQ],
				FileBaseName[d]->
					{
						"Symbols"->
							Select[
								FileNames["*.nb",d,5],
								StringMatchQ[
									FileNameJoin@{
										d,
										"*",
										"ReferencePages",
										"Symbols",
										"*.nb"
										}
									]
								],
						"Guides"->
							Select[
								FileNames["*.nb",d,4],
								StringMatchQ[
									FileNameJoin@{
										d,
										"*",
										"Guides",
										"*.nb"
										}
									]
								],
						"Tutorials"->
							Select[
								FileNames["*.nb",d,4],
								StringMatchQ[
									FileNameJoin@{
										d,
										"*",
										"Tutorials",
										"*.nb"
										}
									]
								]
						}
				],
		DirectoryQ@FileNameJoin@{d,"ref"}||
			DirectoryQ@FileNameJoin@{d,"guide"}||
			DirectoryQ@FileNameJoin@{d,"tutorial"},
			Append[
				extractDirectoryDocs/@
					Select[FileNames["*",d],DirectoryQ],
				FileBaseName[d]->
					{
						"Symbols"->
							(FileBaseName/@
								Select[FileNames["ref/*.html",d,\[Infinity]],
									FileBaseName@DirectoryName[#]==="ref"&
									]),
						"Guides"->
							(FileBaseName/@
								Select[FileNames["guide/*.html",d,\[Infinity]],
									FileBaseName@DirectoryName[#]==="guide"&
									]),
						"Tutorials"->
							(FileBaseName/@
								Select[FileNames["tutorial/*.html",d,\[Infinity]],
									FileBaseName@DirectoryName[#]==="tutorial"&
									])
						}
				],
		True,
			extractDirectoryDocs/@
				Select[FileNames["*",d],DirectoryQ]
		];


DocumentationMultiPackageOverviewNotebook[
	d:_String?DirectoryQ|{__String?DirectoryQ},
	pattern_:"*",
	ops:OptionsPattern[]
	]:=
	With[{d2=
		Select[
			Flatten[extractDirectoryDocs/@Flatten@{d}],
			If[StringQ[pattern],StringMatchQ,MatchQ][First[#],pattern]&
			]},
		DocumentationMultiPackageOverviewNotebook[d2,
			ops
			]
		];
DocumentationMultiPackageOverviewNotebook[
	co_CloudObject,
	pattern_:"*",
	ops:OptionsPattern[]
	]:=
	DocumentationMultiPackageOverviewNotebook[
		Select[If[StringQ[pattern],StringMatchQ,MatchQ][First[#],pattern]&]@
		Flatten@CloudEvaluate@
			With[{
				d=
					FileNameJoin@Flatten@{
						$HomeDirectory,
						Rest@
							URLParse[
								CloudObjectInformation[co][[1,"Path"]],
								"Path"
								]
						}
				},
				extractDirectoryDocs[d]
				],
		ops
		];



