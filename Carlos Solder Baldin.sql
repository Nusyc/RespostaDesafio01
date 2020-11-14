

declare @Columns nvarchar(max) = ''
      , @Query nvarchar(max) = ''
declare @While smallint = 0
      , @AuxWhile smallint = 1

select @While = max(qtd)
from (
          select count(ID_JORNADA_ADICIONAL) qtd
          from JORNADA_ADICIONAL
          group by ID_JORNADA
     ) a

while(@AuxWhile <= @While)
begin
     set @Columns += ', '
     set @Columns += concat('max(case when id_dh_ini = ', @AuxWhile, ' then DH_INICIO_ADICIONAL else NULL end) as DH_INICIO_ADICIONAL_', @AuxWhile, ', ')
     set @Columns += concat('max(case when id_dh_fim = ', @AuxWhile, ' then DH_FIM_ADICIONAL else NULL end) as DH_FIM_ADICIONAL_', @AuxWhile)

     set @AuxWhile += 1
end

set @Query = concat('select j.ID_JORNADA as ID, j.DH_INICIO_JORNADA, j.DH_INICIO_INTERVALO, j.DH_FIM_INTERVALO, j.DH_FIM_JORNADA', @Columns, ' from JORNADA j
     outer apply (
                    select ID_JORNADA
                         , row_number() over(partition by ID_JORNADA order by DH_INICIO_ADICIONAL) as id_dh_ini
                         , row_number() over(partition by ID_JORNADA order by DH_FIM_ADICIONAL) as id_dh_fim
                         , DH_INICIO_ADICIONAL
                         , DH_FIM_ADICIONAL
                    from JORNADA_ADICIONAL
                    where ID_JORNADA = j.ID_JORNADA
               ) src
group by j.ID_JORNADA, j.DH_INICIO_JORNADA, j.DH_INICIO_INTERVALO, j.DH_FIM_INTERVALO, j.DH_FIM_JORNADA')

exec sys.sp_executesql
@stmt = @Query

