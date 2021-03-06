-- DESCOBRIR QUANTAS COLUNAS IREI PRECISAR.

DECLARE @QTD_COLUNAS INT = 0,
		@COLUNAS_DH_INICIO_ADICIONAIS VARCHAR(MAX) = '',
		@COLUNAS_DH_FIM_ADICIONAIS VARCHAR(MAX) = '',
		@COLUNAS_ADICIONAIS VARCHAR(MAX) = ''

;WITH DESCOBRINDO_QTD_DE_COLUNAS
AS
(
select 
	A.ID_JORNADA, COUNT(*) QTD
from
	JORNADA A 
INNER JOIN JORNADA_ADICIONAL B ON  A.ID_JORNADA = B.ID_JORNADA
--WHERE
--	A.ID_JORNADA = 7
GROUP BY
	A.ID_JORNADA
)
SELECT
	@QTD_COLUNAS = MAX(QTD) 
FROM
	DESCOBRINDO_QTD_DE_COLUNAS

;WITH CTE_RECURSIVA
AS
(
	SELECT
		1 AS ID
	UNION ALL
	SELECT
		ID + 1
	FROM
		CTE_RECURSIVA
	WHERE
		ID < @QTD_COLUNAS
)
SELECT
	@COLUNAS_DH_INICIO_ADICIONAIS = 
								STUFF((
									(SELECT
										',' + '[DH_INICIO_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + ']' 
									FROM
										CTE_RECURSIVA
									FOR XML PATH('')
									)),1,1,'')

   , @COLUNAS_DH_FIM_ADICIONAIS = STUFF((
									(SELECT
										',' + '[DH_FIM_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + ']' 
									FROM
										CTE_RECURSIVA
									FOR XML PATH('')
									)),1,1,'')

	, @COLUNAS_ADICIONAIS = STUFF((
									(SELECT
										',' + 'MAX([DH_INICIO_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + ']) AS [DH_INICIO_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + '],' 
										+ 'MAX([DH_FIM_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + ']) AS [DH_FIM_ADICIONAL_' + CONVERT(VARCHAR(100),ID) + ']' 
									FROM
										CTE_RECURSIVA
									FOR XML PATH('')
									)),1,1,'')

declare @COMPLET_COMMAND NVARCHAR(MAX) = '	
;WITH DADOS_PREPARADOS
AS
(
	SELECT
		A.ID_JORNADA,
	   ''DH_INICIO_ADICIONAL_'' + convert(varchar(30),ROW_NUMBER() OVER (PARTITION BY B.ID_JORNADA ORDER BY B.DH_INICIO_ADICIONAL)) nome_col_dh_inicio_adicional,
		''DH_FIM_ADICIONAL_'' + convert(varchar(30),ROW_NUMBER() OVER (PARTITION BY B.ID_JORNADA ORDER BY B.DH_FIM_ADICIONAL)) as nome_col_dh_fim_adicional,
		B.DH_INICIO_ADICIONAL,
		B.DH_FIM_ADICIONAL,
		DH_INICIO_JORNADA,DH_INICIO_INTERVALO,DH_FIM_INTERVALO,DH_FIM_JORNADA
		
	from
		JORNADA A 
	INNER JOIN JORNADA_ADICIONAL B ON A.ID_JORNADA = B.ID_JORNADA

)
	SELECT
		ID_JORNADA, DH_INICIO_JORNADA,DH_INICIO_INTERVALO,DH_FIM_INTERVALO,DH_FIM_JORNADA, ' + @COLUNAS_ADICIONAIS	 + '
		
	FROM
		DADOS_PREPARADOS
	PIVOT (max(DH_INICIO_ADICIONAL) for nome_col_dh_inicio_adicional in( ' + @COLUNAS_DH_INICIO_ADICIONAIS + ' )) pv1
	PIVOT (max(DH_FIM_ADICIONAL) for nome_col_dh_fim_adicional in( ' + @COLUNAS_DH_FIM_ADICIONAIS + ' )) pv2
	GROUP BY 
		ID_JORNADA,
		DH_INICIO_JORNADA,
		DH_INICIO_INTERVALO,
		DH_FIM_INTERVALO,
		DH_FIM_JORNADA
	OPTION(min_grant_percent = 100)
'
EXEC SP_EXECUTESQL @COMPLET_COMMAND


