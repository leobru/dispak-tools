КОКА	СТАРТ	'1'
	М
	конд	п'КОКА  '
	ржа	'7'
	сч	rdzon0
	пв	read(М14)
	уиа	'74003'(М1)
	сч	rdzon7
	пв	read(М14)
	уиа	(М11)
	уиа	'10000'(М2)
G00007	сч	(М1)
	по	G00015
	и	D00600
	нтж	E1
	пе	G00014
	сч	(М1)
	и	E48t33
	зп	(М2)
	слиа	1(М2)
G00014	цикл	G00007(М1)
	Э74	'1'
G00015	сч
	зп	(М2)
	уиа	-511(М1)
	уиа	24(М2)
	сч	D00602
	зп	count
G00020	сч	'73777'(М1)
	сда	64(М2)
	и	D00567
	по	G00026
	зп	D00606
	пв	G00411(М15)
	по	G00026
	сч	count
	сда	64-24
	или	count
	пв	G00374(М15)
G00026	сч	E9
	слц	count
	зп	count
	цикл	G00020(М1)
	слиа	-24(М2)
	пино	G00034(М2)
	уиа	-511(М1)
	сч	E23
	или	D00602
	зп	count
	пб	G00020
G00034	сч	B77
	зп	count
	сч	'72003'
G00036	рзб	hizmsk
	по	G00065
	или	rdpg34
	пв	read(М14)
G00040	сч	e70wrk
	сбр	hizmsk
	сда	64+24
	зп	D00645
	сч	'70002'
	сда	64-23
	пе	G00051
	уиа	outbuf(М17)
	сч	D00645
	сда	64-24
	рзб	D00655
	счм	nofree
	счм	nofree+1
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
	пб	G00062
G00051	зп	D00644
	по	G00062
	нед	D00646
	и	D00646
	уи	М1
	или	D00645
	зп	D00606
	пв	G00411(М15)
G00055	по	G00062
	сч	count
	сда	64-24
	или	count
	пв	G00374(М15)
G00060	сч	D00644
	нтж	E48(М1)
	пб	G00051
G00062	сч	D00645
	или	B77
	зп	count
	сч	'70002'
	пб	G00036
G00065	уиа	(М10)
	уиа	'10000'(М2)
	уиа	'12000'(М3)
G00067	сч	(М2)
	по	G00213
	рзб	hizmsk
	или	rdpg34
	зп	D00644
	сбр	hizmsk
	сда	64+24
	зп	count
	сч	D00644
	пв	read(М14)
	уиа	-24(М4)
	уиа	'70030'(М5)
G00075	сч	(М5)
	или	G00015(М5)
	или	26(М5)
	или	39(М5)
	пе	G00101
	сч	E32
	или	(М3)
	зп	(М3)
G00101	сч	(М3)
	или	E32
	нтж	E32
	по	G00207
	и	E8
	пе	G00207
	сч	E8
	или	(М3)
	зп	(М3)
	и	E32
	пе	G00111
	сч	(М3)
	и	D00571
	нтж	D00647
	по	G00146
G00111	сч	(М3)
	и	D00571
	нтж	D00571
	пе	G00154
	уии	М6(М5)
	уиа	-2(М7)
G00114	сч	(М6)
	по	G00137
	сч
	зп	D00645
	уиа	-2(М16)
	сч	(М6)
G00117	зп	D00644
	и	П77
	слц	D00645
	зп	D00645
	сч	D00644
	сда	64+16
	цикл	G00117(М16)
	сч	D00645
	сбр	П77
	сда	64+11
	зп	D00645
	сч	2(М6)
	сбр	D00661
	сда	64+7
	или	D00645
	зп	D00645
	и	E32
	сда	64-15
	или	D00645
	нтж	(М3)
	и	E48t33
	по	G00137
	уиа	outbuf(М17)
	сч	count
	пв	G00447(М12)
	сч	badkey
	счм	badkey+1
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
G00137	слиа	G00015(М6)
	сч	count
	слц	E6
	зп	count
	цикл	G00114(М7)
	сч	D00650
	и	count
	нтж	count
	зп	count
	сч	G00040+7(М5)
	и	D00604
	пе	G00160
	пб	G00166
G00146	уиа	outbuf(М17)
	сч	count
	пв	G00447(М12)
	сч	frnemp
	счм	frnemp+1
	счм	frnemp+2
	счм	allone
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
	пб	G00207
G00154	сч	(М3)
	и	D00571
	нтж	D00647
	по	G00207
	сч	G00040+7(М5)
	нтж	(М3)
	и	D00667
	по	G00166
G00160	сч	count
	уиа	outbuf(М17)
	пв	G00447(М12)
	сч	linkup
	счм	linkup+1
	счм	allone
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
G00166	уии	М6(М5)
	уиа	-2(М7)
G00167	сч	1(М6)
	и	D00567
	по	G00177
	зп	D00606
	пв	G00411(М15)
	по	G00177
	слиа	2(М7)
	счи	М7
	слиа	-2(М7)
	сда	64-5
	или	count
	зп	D00644
	сда	64-24
	или	D00644
	пв	G00374(М15)
G00177	слиа	G00015(М6)
	цикл	G00167(М7)
	сч	G00040+7(М5)
	и	D00567
	по	G00207
	зп	D00606
	пв	G00411(М15)
	по	G00207
	сч	(М3)
	и	D00667
	или	count
	пв	G00374(М15)
	пб	G00207
G00207	слиа	G00040+8(М5)
	сч	count
	слц	E1
	зп	count
	слиа	1(М3)
	цикл	G00075(М4)
	цикл	G00067(М2)
G00213	пино	G00065(М10)
	уиа	'12000'(М1)
	уиа	'10000'(М2)
G00215	сч	(М2)
	по	G00234
	и	E48t33
	сда	64+24
	зп	count
	уиа	-24(М3)
G00220	сч	(М1)
	и	E8
	пе	G00231
	уиа	outbuf(М17)
	сч	count
	пв	G00447(М12)
	сч	(М1)
	и	E32
	пе	G00226
	сч	lost
	зп	(М17)
G00226	сч	lost+1
	счм	lost+2
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
G00231	сч	count
	слц	E1
	зп	count
	слиа	1(М1)
	цикл	G00220(М3)
	цикл	G00215(М2)
G00234	пио	good(М11)
	уиа	'12000'(М1)
	уиа	'10000'(М2)
	Э64	header
G00236	сч	(М2)
	по	exit
	рзб	hizmsk
	или	rdpg34
	зп	D00644
	сбр	hizmsk
	сда	64+24
	зп	count
	сч	D00644
	пв	read(М14)
	уиа	-24(М3)
	уиа	'70030'(М4)
	уиа	-5(М5)
G00245	уиа	outbuf(М17)
	сч	count
	пв	G00447(М12)
	сч	(М1)
	сда	64+24
	пв	G00447(М12)
	сч	39(М4)
	сда	64+24
	пв	G00447(М12)
	сч	(М1)
	пв	G00447(М12)
	сч	39(М4)
	пв	G00447(М12)
	сч	1(М4)
	пв	G00447(М12)
	сч	14(М4)
	пв	G00447(М12)
	сч	27(М4)
	пв	G00447(М12)
	сч	(М17)
	или	D00601
	зп	(М17)
	сч	(М1)
	и	D00675
	нтж	D00676
	по	G00266
	и	E32
	пе	G00266
	сч	outbuf
	нтж	D00677
	зп	outbuf
G00266	Э64	prnbuf
	сч	count
	слц	E1
	зп	count
	слиа	1(М1)
	слиа	G00040+8(М4)
	слиа	1(М5)
	пино	G00274(М5)
	Э64	tsepar
	уиа	-5(М5)
G00274	цикл	G00245(М3)
	цикл	G00236(М2)
exit	Э74
good	Э64	tgood
	Э74
tgood	кк	0,tgood+2
	кк	0,tgood+2
	конд	в'50000000'
	текст	п'ОШИБКИ В КАТАЛОГЕ НЕ ОБНАРУЖЕНЫ!'
	конд	м40в'377'
outbuf	пам	30
prnbuf	кк	0,outbuf
	кк	0,outbuf
	конд	в'40000000'
tsepar	кк	0,tsepar+2
	кк	0,tsepar+2
	конд	в'40000000'
	текст	п'   -   -   -   -   -   -   -   -   -'
	текст	п'   -   -   -   -   -   -   -   -   -'
	текст	п'   -   -   -   -   -   -'
	конд	п'   - 0'в'377'
G00374	пе	G00375
	выпр	,       why crash instead of termination
G00375	зп	D00654
	сч	(М13)
	пе	G00401
	сч	D00654
	зп	(М13)
	уиа	1(М10)
	пб	(М15)
G00401	уиа	outbuf(М17)
	сч	D00606
	пв	G00447(М12)
	сч	(М13)
	пв	G00471(М12)
	сч	D00654
	пв	G00471(М12)
	сч	doubly
	счм	doubly+1
	счм	allone
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
	пб	(М15)
G00411	и	D00567
	зп	D00444
	сда	64-24
	зп	D00443
	уиа	'10000'(М16)
G00414	сч	(М16)
	по	G00417
	нтж	D00443
	и	E48t33
	по	G00427
	цикл	G00414(М16)
G00417	уиа	outbuf(М17)
	сч	count
	пв	G00447(М12)
	сч	D00443
	рзб	D00702
	или	D00703
	счм	nozone
	счм	nozone+1
	зп	(М17)
	Э64	prnbuf
	уиа	1(М11)
	сч
	пб	(М15)
G00427	слиа	'70000'(М16)
	счи	М16
	умн	E48d25
	счмр	64
	уи	М13
	сч	D00444
	и	D00566
	зп	D00443
	мод	D00443
	слиа	'12000'(М13)
	сч	E1
	пб	(М15)
unused	кк	0,D00442
	кк	0,D00442+4
	конд	в'1005000400000000'
	конд	в'1012000200000000'
	конд	в'1017000600000000'
	конд	в'0065000040000000'
D00442	пам	1
D00443	пам	1
D00444	пам	1
	текст	п'НЕСУЩ.ЗОНА  '
G00447	и	D00706
	по	G00467
	зп	D00504
	сда	64-24
	рзб	D00702
	или	D00707
	счм	D00504
	и	D00566
	умн	E48d40
	счмр	64
	счм	D00504
	сда	64+5
	и	D00570
	умн	E48d13
	счмр	64
	слц	(М17)
	слц	D00651
	сда	64-38
	рзб	D00712
	или	D00713
	счм	D00504
	сда	64-43
	рзб	М32П37
	счм	D00504
	сда	64+5
	и	D00570
	сда	64-16
	или	(М17)
	или	D00715
G00466	зп	(М17)
	пб	(М12)
G00467	сч	spaces
	зп	(М17)
	счм	D00717
	пб	G00466
G00471	зп	D00653
	счи	М12
	зп	ret
	сч	father
	счм	D00653
	сда	64+24
	пв	G00447(М12)
	сч	from
	счм	D00653
	пв	G00447(М12)
G00477	мод	ret
	пб
read	зп	e70wrk
	Э70	e70wrk
	пб	(М14)
e70wrk	пам	2
D00504	пам	2
        ОПРЕ
D00566	конд	п':'
D00567	конд	в'77777777'
D00570	конд	п'3'
D00571	конд	м24в'177'
	конд	м40в'320'
	конд	в'4254400000000000'
E48d25	конд	м47в'1'ф'25'
rdpg34	конд	в'0010340000440000'
rdzon0	конд	в'0010350000440000'
rdzon7	конд	в'0010360000440007'
D00600	конд	п' '
D00601	конд	в'00177777'
D00602	конд	в'177'
	конд	в'00007777'
D00604	конд	м24в'77777777'
count	пам	1
D00606	пам	1
	конд	в'0377740000000000'
header	кк	0,header+2
	кк	0,header+2
	конд	в'44000000'
	конд	х'F8C63636363'
	текст	п'     КВАНТ         ФАКТ.ОТЕЦ     ОТЕЦ ИЗ СВЯЗИ  '
	текст	п' ССЫЛАЮТСЯ ИЗ    ПРОД.ИЗ СВЯЗИ      '
	текст	п'  Н  И  Ж  Н  И  Е     У  Р  О  В  Н  И   '
allone	конд	в'-1'
E48t33	конд	в'7777740000000000'
B77	конд	п'D'
hizmsk	конд	в'0360000000007777'
D00644	пам	1
D00645	пам	1
D00646	конд	в'00077777'
D00647	конд	п'D000'
D00650	конд	в'340'
D00651	конд	в'030'
ret	пам	1
D00653	пам	1
D00654	пам	1
D00655	конд	п'177777'
nofree	конд	п' НЕТ С'
	конд	п'ВОБ. 0'в'377'
П77	конд	п'77'
D00661	конд	м30в'2114'
badkey	конд	п'ПЛОХОЙ'
	конд	п' КЛЮЧ0'в'377'
frnemp	текст	п'СВОБ.КВАНТ НЕ ПУСТ'
D00667	конд	м24в'77777577'
linkup	текст	п'ССЫЛКА ВВЕРХ'
lost	текст	п'ПЛОХО:ПОТЕРЯ'
	конд	п'Н !  0'в'377'
D00675	конд	м24в'377'
D00676	конд	м24в'277'
D00677	конд	п'6'
doubly	текст	п'ДВАЖДЫ ЗАНЯТ'
D00702	конд	п' 77770'
D00703	конд	п' '
nozone	конд	п'НЕТ ЗО'
	конд	п'НЫ ! 0'в'377'
D00706	конд	в'77777577'
D00707	конд	п':'
E48d40	конд	м47в'1'ф'40'
E48d13	конд	м47в'1'ф'13'
D00712	конд	п'177700'
D00713	конд	п'=0'в'143'
М32П37	конд	м32п'37'
D00715	конд	п'/0 0'в'143'
spaces	конд	п'      '
D00717	конд	п'    00'м8в'143'в'143'
father	конд	п' ОТЕЦ:'
from	конд	п'ИЗ:000'м16в'143'м8в'143'в'143'
	конд	п'КОКА  '
	ФИНИШ
