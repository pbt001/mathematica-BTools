(* ::Package:: *)



$GoogleAPIUsername::usage=
	"The username for current Google API access";
$GAClientID::usage=
	"The client ID for current Google API access";
$GAClientSecret::usage=
	"The client ID for current Google API access";
GoogleAPIClearAuth::usage=
	"Clears authentication data for the current user";


$GAVersion::usage="";
$GAParameters::usage="";


GAOAuthenticate::usage="";
GAOAuthTokenData::usage="";
$GAOAuthToken::usage="";
GAOAuthCodeURL::usage="";
GAOAuthRefreshRequest::usage="";


$GAParamMap::usage="";
GAPrepParams::usage="";
GARequest::usage="";
GACall::usage="";
$GAApplyRequests::usage="";


$GAActiveHead::usage="";
GAParse::usage="";
GAErrorString::usage="";
$GALastError::usage="";


Begin["`Private`"];


(* ::Subsection:: *)
(*Settings*)



$GASettings=
	Replace[
		Do[
			With[{f=PackageFilePath["Private", "Config", d]},
				If[FileExistsQ@f,
					Return[
						Replace[Quiet@Import@f,
							{ 
								o_?OptionQ:>Association@o,
								_-><||>
								}
							]
						];
					Break[]
					]
				],
			{d,
				{
					"GoogleConfig.m",
					"GoogleConfig.wl"
					}
				}
			],
		Null-><||>
		];


(* ::Subsection:: *)
(*Parameters*)



(* ::Subsubsection::Closed:: *)
(*Keys*)



$GoogleAPIUsernameName="GoogleAPIUsername";
$GAClientIDName="GoogleAPIClientID";
$GAClientSecretName="GoogleAPIClientSecret";


If[FreeQ[Attributes[$GACache], ReadProtected],
	SetAttributes[$GACache, ReadProtected]
	];
If[FreeQ[Attributes[$GACache], Locked],
	SetAttributes[$GACache, Locked]
	];


$GACacheSym:=
	If[TrueQ@$GASettings["UseKeychain"], $Keychain, $GACache]


GALoadParameter[key_]:=
	With[{s=$GACacheSym},
		Replace[
			s[key],
			Except[_String?(StringLength@#>0&)]:>
				(
				s[key]=
					Replace[
						SelectFirst[
							PackageFilePath["Private",#]&/@
								{
								key<>".wl",
								key<>".m"
								},
							FileExistsQ,
							None
							],{
						f_String:>
							Import[f]
						}]
					)
			]
		];
GALoadParameter[key1_, key2_]:=
	Replace[
		$Keychain[{key1, key2}],
		Except[_String?(StringLength@#>0&)]:>
			(
			$Keychain[{key1, key2}]=
				Replace[
					Replace[
						SelectFirst[
							PackageFilePath["Private",#]&/@
								{
								key1<>".wl",
								key1<>".m"
								},
							FileExistsQ,
							None
							],
					{
						f_String:>
							Import[f]
						}
					],
				Except[_String?(StringLength@#>0&)]:>
					Replace[$Keychain[key1],
						Except[_String?(StringLength@#>0&)]->None
						]
				]
				)
		];


If[!MatchQ[OwnValues[$GoogleAPIUsername],{_:>(_String?(StringLength@#>0&))}],
	$GoogleAPIUsername:=
		$GoogleAPIUsername=
			GALoadParameter[$GoogleAPIUsernameName]
	];


GAGetClientID[userName_]:=
	GALoadParameter[$GAClientIDName, userName]


If[!MatchQ[OwnValues[$GAClientID],{_:>(_String?(StringLength@#>0&))}],
	$GAClientID:=GAGetClientID[$GoogleAPIUsername]
	];


GAGetClientSecret[clientID_]:=
	GALoadParameter[$GAClientSecretName, clientID]


If[!MatchQ[OwnValues[$GAClientSecret],{_:>(_String?(StringLength@#>0&))}],
	$GAClientSecret:=GAGetClientSecret[$GAClientID]
	];


(* ::Subsubsection::Closed:: *)
(*Token*)



If[!MatchQ[OwnValues[$GAOAuthToken],{_:>(_String?(StringLength@#>0&))}],
	$GAOAuthToken:=
		GAOAuthenticate[$GoogleAPIUsername]
	];


(* ::Subsubsection::Closed:: *)
(*Parameters*)



$GAVersion=3;


$GAParameters=
	<|
		"Root"->
			<|
				"Scheme"->"https",
				"Domain"->"www.googleapis.com",
				"Path"->{}
				|>,
		"OAuthCode"->
			<|
				"Domain"->"accounts.google.com",
				"Path"->
					{"o","oauth2","v2","auth"},
				"Query"->
					{
						"response_type"->"code",
						"redirect_uri"->"http://localhost/oauth2callback"
						}
				|>,
		"OAuthToken"->
			<|
				"Path"->{"oauth2","v4","token"}
				|>,
		"Drive"->
			<|
				"Path":>
					{"drive","v"<>StringTrim[ToString@$GAVersion,"v"]},
				"Query"->{}
				|>,
		"AnalyticsReporting"->
			<|
				"Domain"->
					"analyticsreporting.googleapis.com",
				"Path":>
					{"v"<>StringTrim[ToString@$GAVersion,"v"]},
				"Query"->{}
				|>,
		"UploadFile"->
			<|
				"Path":>
					{"upload","drive",
						"v"<>StringTrim[ToString@$GAVersion,"v"],
						"files"},
				"Query"->{}
				|>,
		"RequestData"->
			<|
				"Headers"->{
					"Authorization":>
						"Bearer "<>$GAOAuthToken
					}
				|>
		|>;


(* ::Subsubsection::Closed:: *)
(*URLAssoc*)



GAURLAssoc[
	Optional[None,None],
	params___?OptionQ
	]:=
	ReplacePart[#,
		{(*
			"Path"\[Rule]#["Path"],*)
			"Domain"->Replace[#["Domain"],{___,d_}:>d]
			}
		]&@
	Merge[
		Flatten@{
			$GAParameters["Root"],
			Cases[Flatten@Map[Normal]@{params},
				r:(Rule|RuleDelayed)[k_,_]:>
					If[MatchQ[k,
							"Scheme"|"Domain"|"Query"|"Path"|"Username"|"Password"|"Port"
							],
						r,
						"Query"->r
						]
				]
			},
		Replace[{l_}:>l]@*Flatten
		];
GAURLAssoc[s:_String|{__String},o___?OptionQ]:=
	GAURLAssoc[
		Lookup[$GAParameters,Flatten@{s}],
		o
		];


(* ::Subsection:: *)
(*Auth*)



(* ::Subsubsection::Closed:: *)
(*Clear*)



GoogleAPIClearAuth[
	user:(_String|Automatic):Automatic,
	clientID:_String|Automatic:Automatic,
	scope:_String?GAOAuthScopeQ:"drive"
	]:=
	With[{
		u=
			StringTrim[
				Replace[user, Automatic:>$GoogleAPIUsername],
				"@gmail.com"
				],
		cid=
			Replace[clientID, Automatic:>$GAClientID],
		kc=$GACacheSym
			},
		kc[{u,cid,scope,"token"}]=.;
		kc[{u,cid,scope,"code"}]=.;
		];


(* ::Subsubsection::Closed:: *)
(*Scopes*)



$GAOAuthScopes=
	<|
		"drive"->
			{
				"file",
				"appdata",
				"metadata",
				"metadata.readonly",
				"photos.readonly",
				"readonly",
				"scripts"
				}
		|>;


GAOAuthScopeQ[s_]:=
	(KeyMemberQ[$GAOAuthScopes,ToLowerCase@s]||
		With[{sp=StringSplit[ToLowerCase@s,".",2]},
			MemberQ[
				$GAOAuthScopes[First@sp],
				Last@sp
				]
			]
		);


(* ::Subsubsection::Closed:: *)
(*Requests*)



GAOAuthCodeURL[
	clientID_,
	scope_
	]:=
	With[{
		cid=
			Replace[clientID,
				Automatic:>
					$GAClientID
				],
		s=URLBuild@{"https://www.googleapis.com/auth",scope}
		},
		URLBuild@
			GAURLAssoc["OAuthCode",
				"client_id"->cid,
				"scope"->s
				]
		];


GAOAuthTokenRequest[code_]:=
	HTTPRequest[
		URLBuild@GAURLAssoc["OAuthToken"],
		<|
			"Method"->"Post",
			"Body"->{
				"code"->code,
				"client_id"->$GAClientID,
				"client_secret"->$GAClientSecret,
				"grant_type"->"authorization_code",
				"redirect_uri"->"http://localhost/oauth2callback"
				}
			|>
		];
GAOAuthRefreshRequest[token_]:=
	HTTPRequest[
		URLBuild@GAURLAssoc["OAuthToken"],
		<|
			"Method"->"Post",
			"Body"->{
				"refresh_token"->token,
				"client_id"->$GAClientID,
				"client_secret"->$GAClientSecret,
				"grant_type"->"refresh_token"
				}
			|>
		];


(* ::Subsubsection::Closed:: *)
(*Auth*)



GAOAuthenticate[
	user:(_String|Automatic):Automatic,
	clientID:_String|Automatic:Automatic,
	scope:_String?GAOAuthScopeQ:"drive"
	]:=
	With[{
		u=
			StringTrim[
				Replace[user, Automatic:>$GoogleAPIUsername],
				"@gmail.com"
				],
		cid=
			Replace[clientID, Automatic:>$GAClientID]
			},
		With[{a=GAOAuthTokenData[u, cid, scope]},
			Block[{
				$GAOAuthTokenDataTmp=a,
				$GAOAuthTokenCalls=
					If[!IntegerQ@$GAOAuthTokenCalls, 0, $GAOAuthTokenCalls]
				},
				If[$GAOAuthTokenCalls<4&&AssociationQ@a,
					$GAOAuthTokenCalls++;
					If[
						Quantity[ToExpression@#,"Seconds"]>(Now-#2)&@@
							Lookup[a,{"expires_in","LastUpdated"}, 3600],
						Lookup[a,"access_token"],
						If[KeyMemberQ[a,"refresh_token"],
							Replace[Import[GAOAuthRefreshRequest@a["refresh_token"],"RawJSON"],{
								r_Association:>
									With[{kc=$GACacheSym},
										kc[{u,cid,scope,"token"}]=
											Append[r,"LastUpdated"->Now];
										GAOAuthenticate[u,cid,scope]
										],
								_->$Failed
								}],
							If[$GAOAuthTokenCalls>1&&KeyMemberQ[a,"access_token"],
								a["access_token"],
								GoogleAPIClearAuth[u,cid,scope];
								GAOAuthenticate[u,cid,scope]
								]
							],
						$Failed
						],
					$Failed
					]
				]
			]
		];


(* ::Subsubsection::Closed:: *)
(*OAuthTokenData*)



$GAKeyExample=Image[CompressedData["
1:eJzsvWdsrN12HqY4TpAECRCk/TMCBwkSx05gK4lj50ckBbDjyHbiOJBiBCmQ
YkmQEl0bV1f3O4dteiFnhjPsvXdy2HvvvffeO4e9c4bkk7X2OxzOkEOec75z
7v0+Ke8Gtr6rw3nb3nut9Tx7lf2Xf/ef/ePf/wu/8iu/8if/Cv2ff/w73/3G
T3/6Ox//l3+T/p/f+smf/OEf/OT3/un/8JOf/d4f/N5P/9bv/ov0j/8l9X+V
/sdfpP+en59D7nKXu9zlLne5y13ucpe73OUud7nLXe5yl7vc5S53uctd7nKX
u9zlLne5y13ucpe73D/VT09P5S53uctd7nKXu9zlLne5y93Te3t75S53uctd
7nKXu9zlLne5y93THx4e5C53uctd7nKXu9zlLne5y93T/1w3pxM4OQR2NoDt
NbnLXe5yl7vc5S53ucv9l9cZgzIWZUwqtx+uzYwASQbg9/8u8Bv/HvAf/Yrc
5S53uctd7nKXu9zl/sN3xqaMURmrMmaV2y+2XV4A6RbgN//y23Pyn/1F4D//
l+Qud7nLXe5yl7vc5S73X15nDPoWPmXsyhiWsazcvl27vweybMDf/Neex5rn
4if/CMiJAkZ7gBMHHv+8x1PJTW5yk5vc5CY3ucntR9sEFiVMKrApY9Q//p8k
zPqEXxnLMqZlbCu3r2ur88D//Fefx/bv/ftAcYrMw+QmN7nJTW5yk5vc5Pbj
b4xZGbsyhn3Cs4xtGePK7fu1hmLgb/zLz7zLniz7CuQmN7nJTW5yk5vc5PZn
rgkMS1jWExfDGJexrty+rBUmAP+xm2v97q8Dh/s/9BvJTW5yk5vc5CY3uclN
bl/XGNMytmWMy1iXMa/cPq9VZj/7YjR/KPsO5CY3uclNbnKTm9zk9uemCWxL
GNeDdxn7yu39NtIN/BX3eJl++kO/jdzkJje5yU1ucpOb3OT2i2mMdRnz/qf/
goSB5ea/nR4Dv/5vS2P1s9/G4+PjD/1GcpOb3OQmN7nJTW5yk9svpAmsS5hX
YF/GwIyF/7w1+savxvTK33uuXXR1+U1e61s3/kaZuchNbnL7s9hk/fVnoUm2
VN4ik9u3bI/fC6PJa/GX1hjzPtU8Yiz856g9Pj7gaHsLGxvbOLv6gvOnaeHd
39/DeXsLTAw8x2T9KH0tD7g8cWB9bR07J1d4+JHJDM8Bj6Xon5G/8fgg/dYj
+57rP33tw4P02wc5T+Sr2uPD85x9vu5+/OJrHtxz/fBLWrSPj49+19Iv+j0e
v2AN/6Dt8XkO/XWWq2/vQ33EzeUR1kh/HZxc/ih4As+X6+4aJyenop+enuLs
/BK3rvfX9uevIy9ZeedX9/cuGptzev4JvYfUzy+v4bp/+Cxs9ED3vyX7zu8v
vuHsAnfO95/55hvT3J8f7mJ9fQMOx/FXzdPDO2vMt38DefnEmn7rOQ9eOvB9
mXj87GdJ8vP1n+R+2PN9v+CmnrF/YSM9OuozdODTPV7KwtP6f2uM/cnOw/0t
9vZ2sLG9g7O7z/sOXotnjj3CdZvYP/50rfmHd+b5xZ09v33GEN527Y2rHu9x
d3PtkbPTs3Nc3bre1BXPeuIzMM17z+b15nLhWugI97PP+dnOL1oTn9UY+7pz
mG8HO+lZZ7i8ufv2z/klN+fNMcqsWgQqbOif3Pmsax7unXBsLWOwtx3V1VU4
+q2/Kcbm5vd/E46zmx+FDfNuD85TDDSlICAgGFb7AK6/gAr9wpvrDltL42hv
70BHZxdGJuZw+c4APrpusT7TS7/twebRmdBbJ7tL6KTrewbmcHbtevPahwcn
VmbH0dHRiZHJedz8Aj7n/w+N9e8OjWN3ZzvNwxCWNo4+5yrcHq+gr7tTzPPK
ruOTcvLoOsfUyCD9vh/zy45v8ervP4/0+PHOslhL/SMruL1/FO/9eHOIiZF+
seamFr/9ezw+3OFgdUbIQP/Iqvu5P8JGsnZ6uIrerg50dnb69I6ODrTT+AyP
T2F9y0Hf8O3O12GMsDRYhMCAQKQ1DuH0Bz665955he3lKTRWFCAhMhI2WwQi
IiKRmJaLhtZeLK/v4OYV1pDW0eQoraMOXkcHb96fddrF6S76u7vQ0zeMvbOr
178hDHF1soOpoU7Yc1IQabXSe9gQaYtEalYROvpHseU4f4eLPJLtO8PieD9K
89Pp/aVviEnIRE37EPaOv3wv6ZZwSHt6DFTBCqQVVuPwyy5/fq/bU4wP9r1a
Y/5678gMTq6+P09gLObYZ5lvf/MZrK/6x2dxcuOFCe/OMTcxKGT23Xfs7sXE
+qEYywfic0cbCzSvbOte/7arqxfDY1PYcZx9Fg5/fxjvcX28IdZQZ1c3Ztb3
cfcZw+S6JZ3b3yu+eXBmA5e30ns8OC+wtsi2swvjU5vv6O5HwsLHGKH56+7u
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
Jeqs4lSGCfXtozHnCMvwDrWr3Kccf7HlI4yjtW4PdZbXd66znB+9a5SshlqK
p4/6CJkqVq4rqY8wQD7C0QQfoZ19hGMck2uD3XASh0ifZhpMKrdhmsqveBJ6
Z3XSOaj0X9dV5SNkk4/g2dFHuKp8hKPKRxiNbR2WArQP1eQqPa5qtWQaYbNb
SQ+eUP7BqQwzLrQ/wsKmmNvyEQ6np/IRoPR88Hk/Sg3amQX7CLc24hGi9Uqa
z9iRzuv7o8OqZonJbIHFYkZ2Rrqq5cp3EI3WSjz0b+k73qO9D27Ann5K2Rbu
o2zSABwfcJQ1B+0L9vKL8AU2ati+xNTje6QfdCrOhffTmR9/XWniW3/5jfIN
+DwlI9uO0rIS6E7wPn8Cjvxmdd4bDo7jcnWedg+Jz1WzzdQ/NujJp/+I75Ww
H3Dh/madMxUDMXof5VynQdWDPU5jaoQhOwMWI9si0i60n9jySnBveJz22wtk
13JQf/Fu3H1AXvdD3ddQmGsnraMnjUO2gnS53XUW1x8+3arbA+1OwNVyB8z2
s+gdia9HwP93va4UFvqu1VFKmm9rz+SaEp6Pr6Mw/STWv/sl7d1K980Uw7lI
Nv8eKl1W2seN0fZQX+Tmo7VzAJGV7feP17EQfoE7l2tJQ5rUM5v0NLctFhSU
N+ER7b2JMRJrqjZQS3W+aq+Z+s1sJLtYVI2e0TG4BzrgoPVRfnUAcSWx17X6
9ReqCpXvwm3T03ctVicqzt+Afyayx7X86aHy6Lc3Ipf2qLLqVsSOAu+H91sK
VE3zqo7HSbQijcPDK+pZbSUtGAukPuFYWQnjZl05rEYrKmuubYtj0nJqXq8r
gc1k0PqB9LjFYqU95TLcE3Pb+oHP46bRfb0edrNBfZbnp576sLi6GY/9s4lx
xmRP/E+6ca7EpX2WtDfrIxP1dUPbPbwIbBn/rZjlUyiquQ3P026yGxb1eabF
RM9wvh2+2WR5bWjdevrQcDaP/By9+i2DGlMXmm/1IRDZdmjC8SJjQ2gsK9Dq
39HneX66yhrQ7/aj43w1bDYnLjzQ5r+K275cRc9tQ/X5DsR6kOsrIQx2NpNN
d6DmcnwMDu8/g9eqqO1OdPRt3aPnd/7unnbk2cl+Zeqg0xEzs6hf7KrGeWQ5
mX3mmot+1PIzWpyoadkWc7a2oO4/W2he5HIN+3B8bbfg+BM00neNNM666G9m
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
FAqFQqFQKBQKhcJd+X8AMGyM
"], "Byte", ColorSpace -> "RGB", Interleaving -> True];


GAOAuthTokenData[
	user:_String|Automatic:Automatic,
	clientID:_String|Automatic:Automatic,
	scope:_String?GAOAuthScopeQ:"drive"
	]:=
	Replace[$GAOAuthTokenDataTmp,
		Except[_String]:>
			With[
				{
					u=
						StringTrim[
							Replace[user,Automatic:>$GoogleAPIUsername],
							"@gmail.com"
							],
					cid=
						Replace[clientID,Automatic:>$GAClientID],
					kc=$GACacheSym
					},
				Replace[kc[{u,cid,scope,"token"}],
					Except[_Association?(KeyMemberQ["access_token"])]:>
						Replace[
							Replace[kc[{u,clientID,scope,"code"}],
								Except[_String?(StringLength@#>0&)]:>
									Replace[
										OAuthDialog[
											"Google OAuth Authorization",
											{
												{"Google OAuth",GAOAuthCodeURL[cid,scope]},
												$GAKeyExample
												},
											$GAParameters["Root","Domain"]
											],
										s_String?(StringLength@#>0&):>
											(kc[{u,cid,scope,"code"}]=s)
										]
								],{
							code_String?(StringLength@#>0&):>
								Replace[Import[GAOAuthTokenRequest[code],"RawJSON"],
									r_Association?(KeyMemberQ["access_token"]):>
										(
											kc[{u,cid,scope,"token"}]=
												Append[r,"LastUpdated"->Now]
											)
									]
							}]
					]
				]
		];


(* ::Subsection:: *)
(*Requests*)



(* ::Subsubsection::Closed:: *)
(*PrepParams*)



$GAParamMap=<||>;


GAPrepType//Clear
GAPrepType[n_?NumericQ]:=
	ToString[n];
GAPrepType[n_?DateObjectQ]:=
	DateString[n, "ISODate"];
GAPrepType[q_Quantity]:=
	ToString@
		QuantityMagnitude@
			If[CompatibleUnitQ[q, "Seconds"], 
				UnitConvert[q, "Seconds"],
				q
				];
GAPrepType[l_List]:=
	GAPrepType/@l;
GAPrepType[(Rule|RuleDelayed)[k_, v_]]:=
	k->GAPrepType[v];
GAPrepType[e_]:=e;


GAPrepParamVals[ops_]:=
	Replace[
		ops,
		{
			(h:Rule|RuleDelayed)[s_String, o_]:>
				s->GAPrepType[o]
			},
		1
		];
GAPrepParams[ops_]:=
	DeleteCases[
		GAPrepParamVals@Flatten@Normal@{ops},
		_->Automatic
		];
GAPrepParams[ops_, fn_, key_]:=
	GAPrepParams@
		FilterRules[{ops, Options[fn]}, Lookup[$GAParamMap, key, Options[fn]]]; 
GAPrepParams[ops_, fn_]:=
	GAPrepParams[ops, fn, None]


(* ::Subsubsection::Closed:: *)
(*GARequest*)



GARequest[
	root:_String|None:None,
	passoc_Association,
	assoc:_Association:<||>
	]:=
	HTTPRequest[
		With[
			{
				urla=
					GAURLAssoc[
						root,
						Sequence@@Norm[passoc]
						]
				},
			URLBuild[KeyDrop[urla, "Port"]]<>
				Replace[urla["Port"],
					{
						s_String:>":"<>s,
						i_Integer:>":"<>ToString[i],
						_->""
						}
					]
			],
		Merge[{
			$GAParameters["RequestData"]/.
				HoldPattern[$GAOAuthToken]:>$GAOAuthToken,
			assoc
			},
			Replace[{
				{f_}:>
					f,
				o:{__?OptionQ}:>
					Merge[o,Last]
				}]@*Flatten
			]
		];


GARequest[
	root:_String|None:None,
	path:_String|{__String}|Nothing,
	query:_Rule|{___Rule}:{},
	assoc:_Association:<||>
	]:=
	HTTPRequest[
		GAURLAssoc[
			root,
			"Path"->path,
			"Query"->query
			],
		Merge[{
			$GAParameters["RequestData"]/.
				HoldPattern[$GAOAuthToken]:>$GAOAuthToken,
			assoc
			},
			Replace[{
				{f_}:>
					f,
				o:{__?OptionQ}:>
					Merge[o,Last]
				}]@*Flatten
			]
		];


(* ::Subsubsection::Closed:: *)
(*GACall*)



GACall[
	h_HTTPRequest,
	read:"Body"|"BodyBytes"|"BodyByteArray"|Automatic:Automatic
	]:=
	If[read===Automatic,
		GAParse@URLRead@h,
		URLRead[h, {"StatusCode",read}]
		];


GACall[
	root:_String|None:None,
	path:_String|{__String}|Nothing:Nothing,
	query:_Rule|{___Rule}:{},
	assoc:_Association:<||>,
	read:"Body"|"BodyBytes"|"BodyByteArray"|Automatic:Automatic
	]:=
	GACall[
		GARequest[root,path,query,assoc,read],
		read
		];


(* ::Subsubsection::Closed:: *)
(*GAParse*)



GAErrorString[h_HTTPResponse]:=
	TemplateApply[
		"(`code`) `message`",
		Lookup[
			Import[h,"RawJSON"],
			"error",
			<|
				"code"->"N/A",
				"message"->"Unknown error format"
				|>
			]
		]


GAParse[a_Association]:=
	Association@
		KeyValueMap[
			StringReplace[
				StringJoin[
					Replace[
						HoldPattern[Capitalize[s_String]]:>
							(ToUpperCase@StringTake[s,1]<>StringDrop[s,1])
						]@*Capitalize/@StringSplit[#,"_"]
					],{
				"Id"~~EndOfString->"ID",
				"Url"->"URL",
				"Html"->"HTML"
				}]->
				Which[
					StringEndsQ[#,"_at"],
						DateObject@#2,
					StringEndsQ[#,"url"],
						URL[#2],
					True,
						GAParse@#2
					]&,
		a
		];
GAParse[h_HTTPResponse]:=
	<|
		"StatusCode"->
			h["StatusCode"],
		"Content"->
			If[MatchQ[h["StatusCode"],0|(_?(Between@{200,299}))],
				Switch[
					h["ContentType"],
						_?(StringContainsQ@"text/x-objcsrc"),
							h["BodyByteArray"],
						_?(StringContainsQ@"text/"),
							Import[h,"Text"],
						_,
							GAParse@
								Replace[
									Quiet@Import[h,"RawJSON"],
									Except[_String|_Association|_List]:>
										Import[h,"Text"]
									]
					],
				With[
					{
						head=
							If[$GAActiveHead===Unevaluated[$GAActiveHead], 
								GoogleDrive, 
								$GAActiveHead
								],
						errStr=GAErrorString@h
						},
					$GALastError=errStr;
					Message[head::err, errStr]
					];
				$Failed
				]
		|>;
GAParse[s_String]:=
	If[StringLength@StringTrim@s>0,
		Which[
			Quiet[
				AllTrue[
					URLParse[s,{"Scheme","Domain"}],
					StringQ
					],
				URLParse::nvldval
				],
				URL[s],
			StringContainsQ[s,Verbatim["@"]]&&
			Not@FailureQ@
				Interpreter["EmailAddress"][s],
					Interpretation[
						Hyperlink[s,"mailto:"<>s],
						s
						],
			True,
				s
			],
		s
		];
GAParse[l_List]:=
	GAParse/@l;
GAParse[e_]:=
	e;


End[];



