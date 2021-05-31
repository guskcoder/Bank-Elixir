defmodule Conta do
  defstruct usuario: Usuario, saldo: 1000
  @contas "Contas.txt"

  def cadastrar(usuario) do
    case buscar_por_email(usuario.email) do
      nil ->
        binary =
          ([%__MODULE__{usuario: usuario}] ++ buscar_contas())
          |> :erlang.term_to_binary()

        File.write(@contas, binary)

      _ ->
        {:error, "Conta já cadastrada"}
    end
  end

  def buscar_contas do
    {:ok, binary} = File.read(@contas)
    :erlang.binary_to_term(binary)
  end

  def buscar_por_email(email), do: Enum.find(buscar_contas(), &(&1.usuario.email == email))

  def transferir(de, para, valor) do
    de = buscar_por_email(de)
    para = buscar_por_email(para)

    cond do
      valida_saldo(de.saldo, valor) ->
        {:error, "Saldo insuficiente"}

      true ->
        contas = Conta.deletar([de, para])
        de = %Conta{de | saldo: de.saldo - valor}
        para = %Conta{para | saldo: para.saldo + valor}
        contas = contas ++ [de, para]

        Transacao.gravar(
          "transferencia",
          de.usuario.email,
          valor,
          Date.utc_today(),
          para.usuario.email
        )

        File.write(@contas, :erlang.term_to_binary(contas))
    end
  end

  def deletar(contas_deletar) do
    Enum.reduce(contas_deletar, buscar_contas(), fn c, acc -> List.delete(acc, c) end)
  end

  def sacar(conta, valor) do
    conta = buscar_por_email(conta)

    cond do
      valida_saldo(conta.saldo, valor) ->
        {:error, "Saldo insuficiente"}

      true ->
        contas = buscar_contas()
        contas = List.delete(contas, conta)
        conta = %Conta{conta | saldo: conta.saldo - valor}
        contas = contas ++ [conta]
        File.write(@contas, :erlang.term_to_binary(contas))
        {:ok, conta, "Mensagem de email encaminhada!"}
    end
  end

  defp valida_saldo(saldo, valor), do: saldo < valor
end
