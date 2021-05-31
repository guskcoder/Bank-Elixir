defmodule Transacao do
  defstruct data: Date.utc_today(), tipo: nil, valor: 0, de: nil, para: nil

  @transacoes "transacoes.txt"

  def gravar(tipo, de, valor, data, para \\ nil) do
    transacoes =
      buscar_transacoes() ++
        [%__MODULE__{tipo: tipo, de: de, valor: valor, data: data, para: para}]

    File.write(@transacoes, :erlang.term_to_binary(transacoes))
  end

  def todas(), do: buscar_transacoes()

  def por_ano(ano), do: Enum.filter(todas(), &(&1.data.year == ano))

  def por_mes(ano, mes), do: Enum.filter(todas(), &(&1.data.year == ano && &1.data.month == mes))

  def por_dia(data), do: Enum.filter(todas(), &(&1.data == data))

  def calcular_total(), do: todas() |> calcular()

  def calcular_ano(ano), do: por_ano(ano) |> calcular()

  def calcular_dia(data), do: por_dia(data) |> calcular()

  def calcular(transacoes) do
    {transacoes, Enum.reduce(transacoes, 0, fn x, acc -> acc + x.valor end)}
  end

  defp buscar_transacoes() do
    {:ok, binario} = File.read(@transacoes)

    binario
    |> :erlang.binary_to_term()
  end
end
