(* ::Package:: *)



MakeIndentable::usage="Makes a cell or notebook in/dedentable";


IndentationDecrease::usage="Dedents lines in cell";
IndentationIncrease::usage="Indents lines";
IndentationEvent::usage=
	"Determines whether to indent or dedent";


(*
IndentingNewLineReplace::usage=
	"The core function that replaces indenting new lines in RowBoxes";
IndentingNewLineRestore::usage=
	"Restores NewLines";
	*)


IndentationReplace::usage=
	"Replaces all indenting new lines with appropriate indentation";
IndentationRestore::usage=
	"Replaces all raw newlines and indentation with indenting new lines";


Begin["`Private`"];


$IndentationCharDefault="\t";
GetIndentationChar[]:=
	Set[$IndentationChar, 
		Replace[CurrentValue[InputNotebook[], {TaggingRules, "TabCharacter"}],
			Except[_String]->$IndentationCharDefault
			]
		];


(* ::Subsection:: *)
(*Make Indentable*)



With[{pkg=$PackageName<>"`"},
Options[MakeIndentable]=
	{
		"TabCharacter"->Automatic
		};
MakeIndentable[
	nb:_NotebookObject|Automatic:Automatic,
	cell:_String|All|{(All|_String)..}|_CellObject|{__CellObject}:All,
	ops:OptionsPattern[]
	]:=
	Replace[
		Replace[Flatten@List@cell,
			Except[{__CellObject}]:>
				SSCells[SSEditNotebook@nb,cell,"MakeCell"->True]
			],{
		s:{__CellObject}:>
			CompoundExpression[
				SSEdit[s,{
					AutoIndent->True,
					LineIndent->1,
					TabSpacings->1.5
					}];
				Replace[OptionValue["TabCharacter"],
					t_String:>
						SSEditTaggingRules[s,
							{
								"TabCharacter"->t
								}
							]
					];
				SSEditEvents[s,{
					{"MenuCommand","SelectionCloseAllGroups"}:>
						Quiet@Check[
							Needs[pkg];
							IndentationEvent["Indent"],
							SetAttributes[EvaluationCell[],CellEventActions->None]
							],
					{"MenuCommand","SelectionOpenAllGroups"}:>
						Quiet@Check[
							Needs[pkg];
							IndentationEvent["Dedent"],
							SetAttributes[EvaluationCell[],CellEventActions->None]
							],
					{"MenuCommand","InsertMatchingBrackets"}:>
					Quiet@Check[
							Needs[pkg];
							IndentationEvent["Toggle"],
							SetAttributes[EvaluationCell[],CellEventActions->None]
							],
					PassEventsDown->False
					}]
				],
			_->$Failed
			}
		]
	];


(* ::Subsection:: *)
(*Indentation Replacement*)



$indentingNewLine="\[IndentingNewLine]";


$rawNewLine="
]";


indentingNewLineReplace[r:RowBox[data_]]:=
	RowBox@
		Replace[data,{
			"{":>
				CompoundExpression[
					$indentationUnbalancedBrackets["{"]++,
					"{"
					],
			"}":>
				CompoundExpression[
					$indentationUnbalancedBrackets["{"]=
						Max@{$indentationUnbalancedBrackets["{"]-1,0},
					"}"
					],
			"[":>
				CompoundExpression[
					$indentationUnbalancedBrackets["["]++,
					"["
					],
			"]":>
				CompoundExpression[
					$indentationUnbalancedBrackets["["]=
						Max@{$indentationUnbalancedBrackets["["]-1,0},
					"]"
					],
			"(":>
				CompoundExpression[
					$indentationUnbalancedBrackets["("]++,
					"("
					],
			")":>
				CompoundExpression[
					$indentationUnbalancedBrackets["("]=
						Max@{$indentationUnbalancedBrackets["("]-1,0},
					")"
					],
			r2_RowBox:>
				indentingNewLineReplace[r2],
			$indentingNewLine:>
				CompoundExpression[
					Map[
						Which[
							$indentationUnbalancedBrackets[#]>$intentationPreviousLevels[#],
								$indentationLevel[#]++,
							$indentationUnbalancedBrackets[#]<$intentationPreviousLevels[#],
								$indentationLevel[#]=
									Max@{$indentationLevel[#]-1,0}
							]&,
						Keys@$indentationLevel],
					$intentationPreviousLevels=$indentationUnbalancedBrackets,
					"\n"<>
						If[Total@$indentationLevel>0,
							StringRepeat[$IndentationChar,Total@$indentationLevel],
							""
							]
					]
			},
			1];


IndentingNewLineReplace[r:RowBox[data_]]:=
	Block[{
		$indentationUnbalancedBrackets=
			<|"["->0,"{"->0,"("->0|>,
		$intentationPreviousLevels=
			<|"["->0,"{"->0,"("->0|>,
		$indentationLevel=
			<|"["->0,"{"->0,"("->0|>
		},
		indentingNewLineReplace[r]
		];
IndentingNewLineReplace[s_String]:=
	s;


IndentationReplace[nb_:Automatic]:=
	With[{inputNotebook=Replace[nb,Automatic:>InputNotebook[]]},
		With[{selection=IndentationSelection@inputNotebook},
			With[{write=IndentingNewLineReplace@selection},
				NotebookWrite[inputNotebook,write,
					If[MatchQ[write,_String?(StringMatchQ[Whitespace])],
						After,
						All]]
				]
			]
		];


IndentingNewLineRestore[r:RowBox[data_]]:=
	Block[{repTabs=True},
		RowBox[
			Map[
				Switch[#,
					"\n"|$rawNewLine,
						repTabs=True;
						$indentingNewLine,
					_String?(repTabs&&StringMatchQ[#,$IndentationChar~~(""|Whitespace)]&),
						Nothing,
					_RowBox,
						repTabs=False;
						IndentingNewLineRestore[#],
					_,
						repTabs=False;
						#
					]&,
				data
				]
			]
		];


IndentationRestore[nb_:Automatic]:=
	With[{inputNotebook=Replace[nb,Automatic:>InputNotebook[]]},
		With[{selection=IndentationSelection@inputNotebook},
			With[{write=IndentingNewLineRestore@selection},
				NotebookWrite[inputNotebook,write,
					If[MatchQ[write,_String?(StringMatchQ[Whitespace])],
						After,
						All]
					]
				]
			]
		];


IndentationSelection[inputNotebook_]:=
	Replace[NotebookRead@inputNotebook,{
		Cell[BoxData[d_]|d_String,___]:>
			CompoundExpression[
				SelectionMove[First@SelectedCells[],All,CellContents],
				d]
		}];


indentationAddTabsRecursiveCall[RowBox[d:{___}]]:=
	RowBox@
		Replace[d,{
			r_RowBox:>
				indentationAddTabsRecursiveCall[r],
			s_String?(StringMatchQ[$indentingNewLine~~___]):>
				StringInsert[StringDrop[s,1],"\n"<>$IndentationChar,1],
			s_String?(StringMatchQ["\n"~~___]):>
				StringInsert[s,$IndentationChar,2]
				},
			1];
indentationAddTabs[sel_]:=
	Replace[
		sel,{
			{}:>$IndentationChar,
		_String:>
			StringReplace[sel,{
				"\n":>"\n"<>$IndentationChar,
				StartOfString:>$IndentationChar
				}],
		_:>
			Replace[indentationAddTabsRecursiveCall[sel],
				RowBox[{data___}]:>
					RowBox[{$IndentationChar,data}]
					]
		}];


IndentationIncrease[nb_:Automatic]:=
With[{inputNotebook=Replace[nb,Automatic:>InputNotebook[]]},
With[{write=indentationAddTabs@IndentationSelection@inputNotebook},
NotebookWrite[inputNotebook,write,
If[MatchQ[write,_String?(StringMatchQ[Whitespace])],
After,
All]]
]
];


(* ::Text:: *)
(*Need a way to make sure final lines aren\[CloseCurlyQuote]t ignored.*)



indentationDelTabsRecursiveCall[RowBox[d:{___}]]:=
	RowBox@
		Replace[d,{
			r_RowBox:>
				indentationDelTabsRecursiveCall[r],
			$indentingNewLine->
				"\n",
			"\n":>
				CompoundExpression[
					$dedentationRequired=True,
					"\n"
					],
			s_String?(StringMatchQ[$IndentationChar~~___]):>
				CompoundExpression[
					If[$dedentationRequired,
						$dedentationRequired=False;
						StringDrop[s,StringLength[$IndentationChar]],
						s
						]
					]
				},
			1];
indentationDelTabs[sel_]:=
	Replace[sel,
		{
		_String:>
			StringReplace[sel,{
				"\n"<>$IndentationChar:>"\n",
					StartOfLine~~$IndentationChar:>""
				}],
		{}:>"",
		_RowBox:>
			Block[{
				$dedentationRequired=True
				},
				indentationDelTabsRecursiveCall[sel]
				]
		}];


IndentationDecrease[nb_:Automatic]:=
	With[{inputNotebook=Replace[nb,Automatic:>InputNotebook[]]},
		With[{write=indentationDelTabs@IndentationSelection@inputNotebook},
			NotebookWrite[inputNotebook,write,
				If[MatchQ[write,_String?(StringMatchQ[Whitespace])],
					After,
					All]
				]
			]
		];


IndentationEvent["Indent"]:=
	(
		GetIndentationChar[];
		If[Not@FreeQ[NotebookRead@EvaluationNotebook[],$indentingNewLine],
			IndentationReplace[],
			IndentationIncrease[]
			]
		)


IndentationEvent["Dedent"]:=
	(
		GetIndentationChar[];
		IndentationDecrease[]
		)


IndentationEvent["Toggle"]:=
	(
		GetIndentationChar[];
		If[Not@FreeQ[NotebookRead@EvaluationNotebook[],$indentingNewLine],
			IndentationReplace[],
			IndentationRestore[]
			]
			)


IndentationEvent[]:=
	(
		GetIndentationChar[];
		If[AllTrue[
				{"OptionKey","ShiftKey"},
				CurrentValue[EvaluationNotebook[],#]&
				],
			IndentationRestore[],
			Which[
				Not@FreeQ[NotebookRead@EvaluationNotebook[],$indentingNewLine],
					IndentationReplace[],
				CurrentValue["OptionKey"],
					IndentationDecrease[],
				True,
					IndentationIncrease[]
				]
			];
			)


End[];



