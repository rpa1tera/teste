#include "rwmake.ch"
#include "topconn.ch"
#include "TBICONN.CH"
#include "ap5mail.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ FCOMR001 º Autor ³ Adriano Reis       º Data ³  23/05/19   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºManutenção³  									 * Data ³  24/01/08   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ PEDIDO DE COMPRAS (GRAFICO)                                º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
*/


user function fcomr001()

	_cfilsa2 := xfilial("SA2")
	_cfilsb1 := xfilial("SB1")
	_cfilsc7 := xfilial("SC7")
	_cfilse4 := xfilial("SE4")

	cperg := PADR("FCOR01",LEN(SX1->X1_GRUPO))

	_pergsx1()

	if pergunte(cperg,.t.)
		processa({|| imprime()},"Pedido de compras")
	Endif

Return()

Static function imprime()

	procregua(0)

	arial10 :=tfont():new("Arial",,10,,.f.,,,,,.f.)
	arial12 :=tfont():new("Arial",,12,,.f.,,,,,.f.)
	arial14 :=tfont():new("Arial",,14,,.f.,,,,,.f.)
	arial16 :=tfont():new("Arial",,16,,.f.,,,,,.f.)
	arial18 :=tfont():new("Arial",,18,,.f.,,,,,.f.)
	arial20 :=tfont():new("Arial",,20,,.f.,,,,,.f.)
	arial20n:=tfont():new("Arial",,20,,.t.,,,,,.f.)
	arial22 :=tfont():new("Arial",,22,,.f.,,,,,.f.)
	arial24 :=tfont():new("Arial",,24,,.f.,,,,,.f.)

	_adet:={}
	aadd(_adet,{"Item"                ," ",100,0})
	aadd(_adet,{"Código"              ," ",200,0})
	aadd(_adet,{"Descrição do Produto"," ",1350,0})
	aadd(_adet,{"Un"                  ," ",080,0})
	aadd(_adet,{"Quantidade"          ," ",230,1})
	aadd(_adet,{"Valor Unitário"      ," ",280,1})
	aadd(_adet,{"Valor Total"         ," ",280,1})
	aadd(_adet,{"IPI"                 ," ",120,1})
	aadd(_adet,{"SC"                  ," ",190,0})
	aadd(_adet,{"CC"                  ," ",200,0})
	aadd(_adet,{"Dt.Entrega"          ," ",190,0}) 	

	oprn:=tmsprinter():new()
	oprn:setlandscape()
	oprn:setup()

	_nlin:=10

	sc7->(dbsetorder(1))
	sc7->(dbseek(_cfilsc7+mv_par01,.t.))
	While !sc7->(eof()) .and. 	sc7->c7_filial==_cfilsc7 .and. 	sc7->c7_num<=mv_par02

		_npagina :=1
		_cpedido :=sc7->c7_num
		_cmoeda  := getmv("MV_MOEDA"+strzero(mv_par03,1))
		_aitens  :={}
		_aobs    :={}
		_ntotmerc:=0
		_ntotal  :=0
		_nvalipi :=0
		_ndesc1  :=sc7->c7_desc1
		_ndesc2  :=sc7->c7_desc2
		_ndesc3  :=sc7->c7_desc3
		_nvaldesc:=0
		_nvalfre :=0
		_nvaldesp:=0
		_demissao:=sc7->c7_emissao
		_ccond   :=sc7->c7_cond
		_ccomprad:=usrfullname(sc7->c7_user)
		_ntperc  :=0
		_ntaxa   :=sc7->c7_txmoeda
		_ctpfrete:=sc7->c7_tpfrete
		_lmp     :=.f.

		incproc("Imprimindo pedido "+_cpedido) 

		if SC7->C7_CONAPRO = "B"  // ENVIA EMAIL SOMENTE SE O APROVADOR LIBERAR O PEDIDO DE COMPRA.
			Aviso("Pedido Bloqueado","Favor solicitar liberação do pedido "+_cpedido+".",{"Ok"})
			sc7->(dbskip())
			Loop
		Endif	

		sa2->(dbsetorder(1))
		sa2->(dbseek(_cfilsa2+sc7->c7_fornece+sc7->c7_loja))
		se4->(dbsetorder(1))
		se4->(dbseek(_cfilse4+_ccond))

		_impcab()

		While !SC7->(eof()) .AND. 	sc7->c7_filial == _cfilsc7 .AND. 	sc7->c7_num == _cpedido
			xcodfor := ""
			sb1->(dbsetorder(1))
			sb1->(dbseek(_cfilsb1+sc7->c7_produto)) 
			

			sa5->(dbsetorder(2))
			if sa5->(dbSeek(xFilial("SA5")+sc7->c7_produto+sc7->c7_fornece+sc7->c7_loja))
				if !empty(SA5->A5_CODPRF) .and. empty(xcodfor)
					xcodfor:=alltrim(SA5->A5_CODPRF)
				endif
			Endif

			if sc7->c7_moeda==mv_par03
				_nvaluni  := sc7->c7_preco
				_nvaltot  := sc7->c7_total
				_nipi     := sc7->c7_valipi
				_nfrete   := sc7->c7_valfre
				_ndespesa := sc7->c7_despesa
			Else
				_nvaluni  := round(sc7->c7_preco*sc7->c7_txmoeda,5)
				_nvaltot  := round(sc7->c7_quant*_nvaluni,2)
				_nipi     := round(sc7->c7_valipi*sc7->c7_txmoeda,5)
				_nfrete   := round(sc7->c7_valfre*sc7->c7_txmoeda,5)
				_ndespesa := round(sc7->c7_despesa*sc7->c7_txmoeda,5)
			Endif

			if sc7->c7_desc1 <> 0 .or. sc7->c7_desc2 <> 0 .or. sc7->c7_desc3 <> 0
				_ndesconto := calcdesc(_nvaltot,sc7->c7_desc1,sc7->c7_desc2,sc7->c7_desc3)
			Else
				if sc7->c7_moeda == mv_par03
					_ndesconto := sc7->c7_vldesc
				Else
					_ndesconto := Round(sc7->c7_vldesc*sc7->c7_txmoeda,2)
				Endif
			Endif

			_ntotmerc += _nvaltot
			_nvaldesc += _ndesconto
			_nvalipi  += _nipi
			_nvalfre  += _nfrete
			_nvaldesp += _ndespesa

			if mv_par04==1 .or. empty(sc7->c7_segum) .or. empty(sc7->c7_qtsegum) // UNIDADE PRIMARIA
				_cum    := sc7->c7_um
				_nquant := sc7->c7_quant
			Else // UNIDADE SECUNDARIA
				_cum     := sc7->c7_segum
				_nquant  := sc7->c7_qtsegum
				_nvaluni :=_nvaltot/_nquant
			Endif
																	//c7_obs2
			aadd(_aitens,{sc7->c7_item,sc7->c7_produto,sb1->b1_desc,"","",_cum,_nquant,_nvaluni,_nvaltot,sc7->c7_ipi,sc7->c7_numsc,sc7->c7_cc,DTOC(SC7->C7_DATPRF)})  

			if !Empty(SC7->C7_OBS)
				aadd(_aobs,SC7->C7_OBS)
			Endif

			sc7->(dbskip())
		EndDo

		For _ni:=1 to len(_aitens)

			_cdesc2:=_aitens[_ni,4]
			_cobsp :=_aitens[_ni,5]

			_adet[01,2]:= _aitens[_ni,01]
			_adet[02,2]:= _aitens[_ni,02]
			_adet[03,2]:= substr(_aitens[_ni,03],1,75)
			_adet[04,2]:= _aitens[_ni,06]
			_adet[05,2]:= transform(_aitens[_ni,07],pesqpict("SC7","C7_QUANT"))
			_adet[06,2]:= transform(_aitens[_ni,08],pesqpict("SC7","C7_PRECO"))
			_adet[07,2]:= transform(_aitens[_ni,09],pesqpict("SC7","C7_TOTAL"))
			_adet[08,2]:= transform(_aitens[_ni,10],pesqpict("SC7","C7_IPI"))
			_adet[09,2]:= _aitens[_ni,11]
			_adet[10,2]:= _aitens[_ni,12]
			_adet[11,2]:= _aitens[_ni,13]		

			_impdet(_adet,2)
		Next

		_ntotal:=_ntotmerc+_nvalipi+_nvalfre+_nvaldesp-_nvaldesc

		_nobs:=1

		_nlin+=10
		oprn:say(_nlin,50,"DESCONTOS "+transform(_ndesc1,"@E 99.99")+transform(_ndesc2,"@E 99.99")+transform(_ndesc3,"@E 99.99")+transform(_nvaldesc,"@E 999,999,999.99"),arial10,100)
		
		_nlin+=60
		oprn:line(_nlin,50,_nlin,3280)
		
		_nlin+=10
		//oprn:say(_nlin,50,"LOCAL DE ENTREGA E COBRANÇA: RUA SATURNINO RODRIGUES DA SILVA S/N LT.01 A LT.01A BR-153 KM 528 DISTRITO COMERCIAL DE HIDROLANDIA - GOIAS.",arial10,100)
		
		_nlin+=60
		oprn:line(_nlin,50,_nlin,3280)
		
		_nlin+=10
		oprn:say(_nlin,50,"Condição de pagamento: "+_ccond+" - "+alltrim(se4->e4_descri),arial10,100)
		oprn:say(_nlin,2000,"Tipo de frete: "+if(_ctpfrete=="C","CIF",if(_ctpfrete=="F","FOB","")),arial10,100)
		oprn:say(_nlin,3275,"Total das mercadorias: "+transform(_ntotmerc,"@E 999,999,999.99"),arial10,100,,,1)
		
		_nlin+=50
		oprn:say(_nlin,50,"Observações",arial10,100)
		oprn:say(_nlin,3275,"Descontos: "+transform(_nvaldesc,"@E 999,999,999.99"),arial10,100,,,1)
		_nlin+=50
		
		if _nobs<=len(_aobs)
			oprn:say(_nlin,50,_aobs[_nobs],arial10,100)
			_nobs++
		Endif
		
		oprn:say(_nlin,3275,"IPI: "+transform(_nvalipi,"@E 999,999,999.99"),arial10,100,,,1)
		_nlin+=50
		
		if _nobs <= len(_aobs)
			oprn:say(_nlin,50,_aobs[_nobs],arial10,100)
			_nobs++
		Endif
		
		oprn:say(_nlin,3275,"Frete: "+transform(_nvalfre,"@E 999,999,999.99"),arial10,100,,,1)
		_nlin+=50
		
		if _nobs<=len(_aobs)
			oprn:say(_nlin,50,_aobs[_nobs],arial10,100)
			_nobs++
		Endif
		
		oprn:say(_nlin,3275,"Despesas: "+transform(_nvaldesp,"@E 999,999,999.99"),arial10,100,,,1)
		_nlin+=50
		
		if _nobs<=len(_aobs)
			oprn:say(_nlin,50,_aobs[_nobs],arial10,100)
			_nobs++
		Endif
		
		oprn:say(_nlin,3275,"Total geral: "+transform(_ntotal,"@E 999,999,999.99"),arial10,100,,,1)
		_nlin+=60
		oprn:line(_nlin,50,_nlin,3280)
		_nlin+=10
		oprn:box(_nlin,50,_nlin+250,850)
		oprn:say(_nlin+10,60,"Comprador(a)",arial10,100)
		oprn:box(_nlin,860,_nlin+250,1660)
		oprn:say(_nlin+10,870,"Aprovador(es)",arial10,100)
		oprn:box(_nlin,1670,_nlin+250,3280)
		_nlin+=270
		oprn:line(_nlin,50,_nlin,3280)
		_nlin+=10
		oprn:say(_nlin,50,"NOTA: Só aceitaremos a mercadoria se na sua Nota Fiscal constar o número do nosso Pedido de Compras.",arial14,100)
		_nlin+=100
		oprn:say(_nlin,50,"Prezado Parceiro,",arial10,100)
		_nlin+=50
		oprn:say(_nlin,50,"Não recebemos Pedido de Compras Parcial ",arial10,100)
		_nlin+=50
	   ///	oprn:say(_nlin,50,"com prazo de validade mínimo inferior ao solicitado no Pedido de Compras. Qualquer negociação, fora do padrão salientado, será tratada como exceção, e TORNA-SE IMPRESSENDÍVEL COMPROMISSO FORMAL, ",arial10,100)
		_nlin+=50
	   ////	oprn:say(_nlin,50,"ATRAVÉS DE CARTA DE GARANTIA DE RESSARCIMENTO ACOMPANHANDO A MERCADORIA. Tal medida visa exclusivamente reduzir nossos prejuízos com perdas em estoque.",arial10,100)

		oprn:endpage()
	EndDo

		oprn:preview()

Return()

Static function _impcab()
	oprn:startpage()
	_nlin:=10

	oprn:saybitmap(_nlin,0040,Alltrim(SuperGetMv("MV_LOGOPED",,""))+".bmp",0542,0217)

	_nlin+=70
	
	if mv_par03==1
		oprn:say(_nlin,850,"PEDIDO DE COMPRAS - "+_cmoeda+" - "+_cpedido,arial20n,100)
	Else
		oprn:say(_nlin,850,"PEDIDO DE COMPRAS - "+_cmoeda+" Taxa: "+alltrim(transform(_ntaxa,"@E 999,999,999.9999"))+" - "+_cpedido,arial20n,100)
	Endif
	
	oprn:say(_nlin,3275,"Página: "+alltrim(str(_npagina)),arial12,100,,,1)
	_nlin+=50
	oprn:say(_nlin,3275,"Emissão: "+dtoc(_demissao),arial12,100,,,1)

	_nlin+=80
	oprn:line(_nlin,50,_nlin,3280)
	oprn:line(_nlin,1400,_nlin+330,1400)
	_nlin+=30
	oprn:say(_nlin,50,sm0->m0_nomecom,arial12,100)
	oprn:say(_nlin,1450,sa2->a2_cod+"/"+sa2->a2_loja+" - "+sa2->a2_nome,arial12,100)
	_nlin+=60
	oprn:say(_nlin,50,alltrim(sm0->m0_endcob)+" - "+alltrim(sm0->m0_baircob),arial12,100)
	oprn:say(_nlin,1450,alltrim(sa2->a2_end)+" - "+alltrim(sa2->a2_bairro),arial12,100)
	_nlin+=60
	oprn:say(_nlin,50,"CEP: "+transform(sm0->m0_cepcob,"@R 99999-999")+" - "+alltrim(sm0->m0_cidcob)+" - "+sm0->m0_estcob,arial12,100)
	oprn:say(_nlin,1450,"CEP: "+transform(sa2->a2_cep,"@R 99999-999")+" - "+alltrim(sa2->a2_mun)+" - "+sa2->a2_est,arial12,100)
	_nlin+=60
	oprn:say(_nlin,50,"TEL.: "+alltrim(sm0->m0_tel)+" FAX: "+alltrim(sm0->m0_fax),arial12,100)
	oprn:say(_nlin,1450,"TEL.: "+alltrim(sa2->a2_tel)+" FAX: "+alltrim(sa2->a2_fax),arial12,100)
	_nlin+=60
	oprn:say(_nlin,50,if(len(alltrim(sm0->m0_cgc))==11,"CPF: ","CNPJ: ")+transform(sm0->m0_cgc,if(len(alltrim(sm0->m0_cgc))==11,"@R 999.999.999-99","@R 99.999.999/9999-99"))+" Insc. Est.: "+sm0->m0_insc,arial12,100)
	oprn:say(_nlin,1450,if(len(alltrim(sm0->m0_cgc))==11,"CPF: ","CNPJ: ")+transform(sa2->a2_cgc,if(len(alltrim(sa2->a2_cgc))==11,"@R 999.999.999-99","@R 99.999.999/9999-99"))+" Insc. Est.: "+sa2->a2_inscr,arial12,100)
	_nlin+=60
	oprn:line(_nlin,50,_nlin,3280)
	_nlin+=30

	_impdet(_adet,1)

	_npagina++
	
Return()

Static Function _impdet(_adet,_npos)
	local _ncol,_ni,_npad,_nd,_ninc,_ninco,_adesc2

	if _nlin>2000
		oprn:endpage()
		_impcab()
	Endif

	_ninc:=50
	if _npos==2
		if !Empty(_cdesc2)
			_adesc2:={}
			_nd:=1
			
			While ! empty(substr(_cdesc2,_nd,75))
				aadd(_adesc2,{substr(_cdesc2,_nd,75),_ninc})
				_ninc+=50
				_nd+=75
			EndDo
			
		Endif
		
		if ! empty(_cobsp)
			_ninco:=_ninc
			_ninc+=50
		Endif
		
	Endif

	_ncol := 50
	
	For _ni:=1 to len(_adet)
		_npad:=_adet[_ni,4]
		oprn:box(_nlin,_ncol,_nlin+_ninc+10,_ncol+_adet[_ni,3])
		oprn:say(_nlin+5,if(_npad==0,_ncol+10,if(_npad==1,_ncol+_adet[_ni,3]-10,_ncol+int((_adet[_ni,3]/2)))),_adet[_ni,_npos],arial10,100,,,_npad)
		if _npos==2 .and. _ni==3 // DESCRIÇÃO

			if ! empty(_cdesc2)
				for _nd:=1 to len(_adesc2)
					oprn:say(_nlin+_adesc2[_nd,2],if(_npad==0,_ncol+10,if(_npad==1,_ncol+_adet[_ni,3]-10,_ncol+int((_adet[_ni,3]/2)))),_adesc2[_nd,1],arial10,100,,,_npad)
				next
			Endif
			
			if ! empty(_cobsp)
				oprn:say(_nlin+_ninco,if(_npad==0,_ncol+10,if(_npad==1,_ncol+_adet[_ni,3]-10,_ncol+int((_adet[_ni,3]/2)))),_cobsp,arial10,100,,,_npad)
			Endif
			
		Endif
		_ncol+=_adet[_ni,3]
	Next
	
	_nlin+=_ninc+10
	
Return()

Static function _pergsx1()
	local _ni

	_agrpsx1:={}
	aadd(_agrpsx1,{cperg,"01","Do pedido                    ?","mv_ch1","C",06,0,0,"G",space(60),"mv_par01"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"SC7"})
	aadd(_agrpsx1,{cperg,"02","Ate o pedido                 ?","mv_ch2","C",06,0,0,"G",space(60),"mv_par02"       ,space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"SC7"})
	aadd(_agrpsx1,{cperg,"03","Moeda                        ?","mv_ch3","N",01,0,0,"C",space(60),"mv_par03"       ,"Moeda 1"        ,space(30),space(15),"Moeda 2"        ,space(30),space(15),"Moeda 3"        ,space(30),space(15),"Moeda 4"        ,space(30),space(15),"Moeda 5"        ,space(30),"   "})
	aadd(_agrpsx1,{cperg,"04","Unidade de medida            ?","mv_ch4","N",01,0,0,"C",space(60),"mv_par04"       ,"Primaria"       ,space(30),space(15),"Secundaria"     ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})
	//aadd(_agrpsx1,{cperg,"05","Imprimir ou e-mail           ?","mv_ch5","N",01,0,0,"C",space(60),"mv_par05"       ,"Imprimir"       ,space(30),space(15),"E-mail"         ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),space(15),space(15)        ,space(30),"   "})

	For _ni:=1 to len(_agrpsx1)
		If ! sx1->(dbseek(_agrpsx1[_ni,1]+_agrpsx1[_ni,2]))
			sx1->(reclock("SX1",.t.))
			sx1->x1_grupo  :=_agrpsx1[_ni,01]
			sx1->x1_ordem  :=_agrpsx1[_ni,02]
			sx1->x1_pergunt:=_agrpsx1[_ni,03]
			sx1->x1_variavl:=_agrpsx1[_ni,04]
			sx1->x1_tipo   :=_agrpsx1[_ni,05]
			sx1->x1_tamanho:=_agrpsx1[_ni,06]
			sx1->x1_decimal:=_agrpsx1[_ni,07]
			sx1->x1_presel :=_agrpsx1[_ni,08]
			sx1->x1_gsc    :=_agrpsx1[_ni,09]
			sx1->x1_valid  :=_agrpsx1[_ni,10]
			sx1->x1_var01  :=_agrpsx1[_ni,11]
			sx1->x1_def01  :=_agrpsx1[_ni,12]
			sx1->x1_cnt01  :=_agrpsx1[_ni,13]
			sx1->x1_var02  :=_agrpsx1[_ni,14]
			sx1->x1_def02  :=_agrpsx1[_ni,15]
			sx1->x1_cnt02  :=_agrpsx1[_ni,16]
			sx1->x1_var03  :=_agrpsx1[_ni,17]
			sx1->x1_def03  :=_agrpsx1[_ni,18]
			sx1->x1_cnt03  :=_agrpsx1[_ni,19]
			sx1->x1_var04  :=_agrpsx1[_ni,20]
			sx1->x1_def04  :=_agrpsx1[_ni,21]
			sx1->x1_cnt04  :=_agrpsx1[_ni,22]
			sx1->x1_var05  :=_agrpsx1[_ni,23]
			sx1->x1_def05  :=_agrpsx1[_ni,24]
			sx1->x1_cnt05  :=_agrpsx1[_ni,25]
			sx1->x1_f3     :=_agrpsx1[_ni,26]
			sx1->(msunlock())
		Endif
	Next

Return()
