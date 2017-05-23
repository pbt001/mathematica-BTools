(* ::Package:: *)

$packageHeader

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


MakeIndentable[
	nb:_NotebookObject|Automatic:Automatic,
	cell:_String|All{(_String|All)..}|_CellObject|{__CellObject}:All]:=
	With[{s=
		Replace[cell,
			Except[_CellObject|{__CellObject}]:>
				SSCells[SSEditNotebook@nb,cell,True]
			]},
		SSEdit[s,
			AutoIndent->True,
			LineIndent->1,
			TabSpacings->1.5
			];
		SSEditEvents[s,
			{"KeyDown","\t"}:>
				Quiet@Check[
					Needs["BTools`"];
					BTools`IndentationEvent[],
					SetAttributes[EvaluationCell[],CellEventActions->None]
					],
			PassEventsDown->False]
		];


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
							StringRepeat["\t",Total@$indentationLevel],
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
					_String?(repTabs&&StringMatchQ[#,"\t"~~(""|Whitespace)]&),
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
				StringInsert[StringDrop[s,1],"\n\t",1],
			s_String?(StringMatchQ["\n"~~___]):>
				StringInsert[s,"\t",2]
				},
			1];
indentationAddTabs[sel_]:=
	Replace[
		sel,{
			{}:>"\t",
		_String:>
			StringReplace[sel,{
				"\n":>"\n\t",
				StartOfString:>"\t"
				}],
		_:>
			Replace[indentationAddTabsRecursiveCall[sel],
				RowBox[{data___}]:>
					RowBox[{"\t",data}]
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
			s_String?(StringMatchQ["\t"~~___]):>
				CompoundExpression[
					If[$dedentationRequired,
						$dedentationRequired=False;
						StringDrop[s,1],
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
				"\n\t":>"\n",
					StartOfLine~~"\t":>""
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


IndentationEvent[]:=
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


End[];



