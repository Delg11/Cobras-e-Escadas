using Statistics

# Configuração do jogo
const TOTAL_CASAS = 36

const ESCADAS = Dict(
    3 => 16, 5 => 7, 15 => 25, 18 => 20, 21 => 32
)

const COBRAS = Dict(
    12 => 2, 14 => 11, 17 => 4, 31 => 19, 35 => 22
)

# Utilitários
rolar_dado() = rand(1:6)

function mover_jogador(posicao_atual, jogador::Int; 
                      cont_cobras::Bool = false, 
                      escadas_metade::Bool = false, 
                      imunidade_cobra::Bool = false, 
                      debug::Bool = false)
    
    passo = rolar_dado()
    nova_posicao = posicao_atual + passo
    
    # Verifica escadas
    if haskey(ESCADAS, nova_posicao)
        if escadas_metade && rand() < 0.5
            # 50% chance de subir escada
        else
            nova_posicao = ESCADAS[nova_posicao]
        end
    # Verifica cobras
    elseif haskey(COBRAS, nova_posicao)
        if jogador == 2 && imunidade_cobra
            imunidade_cobra = false
            cont_cobras = false
            debug && println("Jogador 2 passou imune pela primeira cobra")
        else
            nova_posicao = COBRAS[nova_posicao]
            cont_cobras = true
        end
    end
    
    return nova_posicao, passo, cont_cobras, imunidade_cobra
end

function jogar_partida(debug::Bool, escadas_metade::Bool; 
                      pos_inicial_j1::Int = 1, 
                      pos_inicial_j2::Int = 1, 
                      imunidade_j2::Bool = false)
    
    jogador1, jogador2 = pos_inicial_j1, pos_inicial_j2
    turno = 0
    contador_cobras = 0
    
    while jogador1 < TOTAL_CASAS && jogador2 < TOTAL_CASAS
        if turno % 2 == 0
            jogador1, dado, encontrou_cobra, _ = mover_jogador(
                jogador1, 1; escadas_metade=escadas_metade, debug=debug
            )
            debug && println("Jogador 1 rolou $dado e foi para casa $jogador1")
        else
            jogador2, dado, encontrou_cobra, imunidade_j2 = mover_jogador(
                jogador2, 2; escadas_metade=escadas_metade, 
                imunidade_cobra=imunidade_j2, debug=debug
            )
            debug && println("Jogador 2 rolou $dado e foi para casa $jogador2")
        end
        
        turno += 1
        encontrou_cobra && (contador_cobras += 1)
    end
    
    vencedor = jogador1 >= TOTAL_CASAS ? 1 : 2
    debug && println("Jogador $vencedor venceu!")
    
    return vencedor, contador_cobras, turno
end

function simular_jogos(n_jogos::Int; 
                      debug::Bool = false, 
                      escadas_metade::Bool = false,
                      pos_inicial_j1::Int = 1, 
                      pos_inicial_j2::Int = 1, 
                      imunidade_j2::Bool = false)
    
    vitorias_j1 = 0
    total_cobras = 0
    total_turnos = 0
    
    for _ in 1:n_jogos
        vencedor, cobras, turnos = jogar_partida(
            false, escadas_metade; 
            pos_inicial_j1=pos_inicial_j1, 
            pos_inicial_j2=pos_inicial_j2, 
            imunidade_j2=imunidade_j2
        )
        
        vitorias_j1 += (vencedor == 1)
        total_cobras += cobras
        total_turnos += turnos
    end
    
    percentual_j1 = 100 * vitorias_j1 / n_jogos
    media_cobras = total_cobras / n_jogos
    media_turnos = total_turnos / n_jogos
    
    if debug
        println("Jogador 1: $(round(percentual_j1, digits=2))% de $n_jogos partidas")
        println("Jogador 2: $(round(100 - percentual_j1, digits=2))% de $n_jogos partidas")
        println("Média de cobras por jogo: $(round(media_cobras, digits=2))")
        println("Média de turnos por jogo: $(round(media_turnos, digits=2))")
    end
    
    return percentual_j1, media_cobras, media_turnos
end

function executar_simulacao_completa(n_jogos::Int, n_repeticoes::Int; 
                                   debug::Bool = false, 
                                   escadas_metade::Bool = false,
                                   pos_inicial_j1::Int = 1, 
                                   pos_inicial_j2::Int = 1, 
                                   imunidade_j2::Bool = false)
    
    resultados_vitorias = Float64[]
    resultados_cobras = Float64[]
    resultados_turnos = Float64[]
    
    for _ in 1:n_repeticoes
        perc_j1, media_cobras, media_turnos = simular_jogos(
            n_jogos; debug=debug, escadas_metade=escadas_metade,
            pos_inicial_j1=pos_inicial_j1, pos_inicial_j2=pos_inicial_j2, 
            imunidade_j2=imunidade_j2
        )
        
        push!(resultados_vitorias, perc_j1)
        push!(resultados_cobras, media_cobras)
        push!(resultados_turnos, media_turnos)
    end
    
    media_vitorias = mean(resultados_vitorias)
    media_cobras = mean(resultados_cobras)
    media_turnos = mean(resultados_turnos)
    
    println("=== Resultados após $n_repeticoes repetições de $n_jogos jogos ===")
    println("Vitórias Jogador 1: $(round(media_vitorias, digits=2))%")
    println("Média de cobras: $(round(media_cobras, digits=2))")
    println("Média de turnos: $(round(media_turnos, digits=2))")
    
    return media_vitorias, media_cobras, media_turnos
end

function encontrar_posicao_equilibrada(escadas_metade::Bool, imunidade_j2::Bool)
    pos_min, pos_max = 2, 35
    resultados = Float64[]
    
    println("Procurando posição inicial equilibrada para Jogador 2...")
    
    for pos in pos_min:pos_max
        media_vitorias, _, _ = executar_simulacao_completa(
            10_000, 1000; pos_inicial_j2=pos, debug=false, 
            escadas_metade=escadas_metade, imunidade_j2=imunidade_j2
        )
        
        push!(resultados, media_vitorias)
        println("Posição $pos → J1 vence $(round(media_vitorias, digits=2))%")
    end
    
    # Encontra posição mais próxima de 50%
    diferencas = abs.(resultados .- 50.0)
    indice_melhor = argmin(diferencas)
    melhor_posicao = indice_melhor + pos_min - 1
    melhor_taxa = resultados[indice_melhor]
    
    println("\n=== RESULTADO ===")
    println("Melhor posição inicial para Jogador 2: $melhor_posicao")
    println("Taxa de vitória J1: $(round(melhor_taxa, digits=2))%")
    
    return melhor_posicao, melhor_taxa, resultados
end

# Exemplo de uso:
# jogar_partida(true, false)
# simular_jogos(1000; debug=true)
# executar_simulacao_completa(1000, 100; debug=true)
# encontrar_posicao_equilibrada(false, true)