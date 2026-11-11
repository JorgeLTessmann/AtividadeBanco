-- \\\ PARTIDOS ///
PARTIDOS
id
nome
sigla
numero

-- \\\ CARGOS ///
CARGOS
id
nome_cargo
quantidade_digitos

-- \\\ CANDIDATOS ///
CANDIDATOS
id
nome
numero
partido_id
cargo_id

-- \\\ ZONA ///
ZONA
id
numero
id_localidades

-- \\\ SECAO ///
SECAO
id
numero
id_zona

-- \\\ ELEITOR ///
ELEITOR
id
nome
cpf
titulo
data_nascimento
id_secao
votou

-- \\\ ELEICOES ///
ELEICOES
id
ano
tipo

-- \\\ LOCALIDADES ///
LOCALIDADES
id
uf
cidade
regiao

-- \\\ VOTOS ///
VOTOS
id
eleicao_id
candidato_id
localidade_id
quantidade_votos

-- \\\ RESULTADOS ///
RESULTADOS
id
eleicao_id
cargo_id
localidade_id
votos_validos
votos_brancos
votos_nulos
votos_invalidados

-- =========================================================
-- DROPS NA ORDEM CORRETA (FILHOS PRIMEIRO, PAIS DEPOIS)
-- =========================================================
DROP TABLE IF EXISTS resultados;
DROP TABLE IF EXISTS votos;
DROP TABLE IF EXISTS eleitores;
DROP TABLE IF EXISTS candidatos;
DROP TABLE IF EXISTS secoes;
DROP TABLE IF EXISTS zonas;
DROP TABLE IF EXISTS eleicoes;
DROP TABLE IF EXISTS localidades;
DROP TABLE IF EXISTS cargos;
DROP TABLE IF EXISTS partidos;




-- \\\ PARTIDOS ///

DROP TABLE IF EXISTS partidos;

CREATE TABLE partidos (
    id         INT             PRIMARY KEY AUTO_INCREMENT,
    nome     VARCHAR(40) NOT NULL UNIQUE,
    sigla     VARCHAR(12) NOT NULL UNIQUE,
    numero     CHAR(2)         NOT NULL UNIQUE
);


-- \\\ CARGOS ///

DROP TABLE IF EXISTS cargos;

CREATE TABLE cargos (
    id                         INT             PRIMARY KEY AUTO_INCREMENT,
    nome_cargo             VARCHAR(40) NOT NULL UNIQUE,
    quantidade_digitos     INT             NOT NULL
);


-- \\\ LOCALIDADES ///

DROP TABLE IF EXISTS localidades;

CREATE TABLE localidades (
    id         INT             PRIMARY KEY AUTO_INCREMENT,
    uf         CHAR(2)         NOT NULL,
    cidade     VARCHAR(60) NOT NULL,
    regiao     VARCHAR(20) NOT NULL
);


-- \\\ ELEIÇÕES ///

DROP TABLE IF EXISTS eleicoes;

CREATE TABLE eleicoes (
    id         INT             PRIMARY KEY AUTO_INCREMENT,
    ano         INT             NOT NULL,
    tipo     VARCHAR(30) NOT NULL
);


-- \\\ ZONAS ///

DROP TABLE IF EXISTS zonas;

CREATE TABLE zonas (
    id                     INT PRIMARY KEY AUTO_INCREMENT,
    numero                 INT NOT NULL,
    localidade_id     INT NOT NULL,

    FOREIGN KEY (localidade_id) REFERENCES localidades(id)
);


-- \\\ SEÇÕES ///

DROP TABLE IF EXISTS secoes;

CREATE TABLE secoes (
    id             INT PRIMARY KEY AUTO_INCREMENT,
    numero         INT NOT NULL,
    zona_id     INT NOT NULL,

    FOREIGN KEY (zona_id) REFERENCES zonas(id)
);


-- \\\ CANDIDATOS ///

DROP TABLE IF EXISTS candidatos;

CREATE TABLE candidatos (
    id                 INT             PRIMARY KEY AUTO_INCREMENT,
    nome             VARCHAR(70) NOT NULL,
    numero             VARCHAR(12) NOT NULL,
    partido_id     INT             NOT NULL,
    cargo_id         INT             NOT NULL,

    FOREIGN KEY (partido_id) REFERENCES partidos(id),
    FOREIGN KEY (cargo_id) REFERENCES cargos(id)
);


-- \\\ ELEITORES ///

DROP TABLE IF EXISTS eleitores;

CREATE TABLE eleitores (
    id                     INT             PRIMARY KEY AUTO_INCREMENT,
    nome                 VARCHAR(70) NOT NULL,
    cpf                     CHAR(11)     NOT NULL UNIQUE,
    titulo                 CHAR(12)     NOT NULL UNIQUE,
    data_nascimento  DATE             NOT NULL,
    secao_id             INT             NOT NULL,
    votou                 BOOLEAN         NOT NULL DEFAULT FALSE,

    FOREIGN KEY (secao_id) REFERENCES secoes(id)
);


-- \\\ VOTOS ///

DROP TABLE IF EXISTS votos;

CREATE TABLE votos (
    id                             INT PRIMARY KEY AUTO_INCREMENT,
    eleicao_id                 INT NOT NULL,
    candidato_id                 INT NOT NULL,
    localidade_id             INT NOT NULL,
    quantidade_votos         INT NOT NULL,

    FOREIGN KEY (eleicao_id) REFERENCES eleicoes(id),
    FOREIGN KEY (candidato_id) REFERENCES candidatos(id),
    FOREIGN KEY (localidade_id) REFERENCES localidades(id)
);


-- \\\ RESULTADOS ///

DROP TABLE IF EXISTS resultados;

CREATE TABLE resultados (
    id                      INT PRIMARY KEY AUTO_INCREMENT,
    eleicao_id          INT NOT NULL,
    cargo_id              INT NOT NULL,
    localidade_id      INT NOT NULL,
    votos_validos      INT NOT NULL,
    votos_brancos      INT NOT NULL,
    votos_nulos          INT NOT NULL,
    votos_invalidados INT NOT NULL,

    FOREIGN KEY (eleicao_id) REFERENCES eleicoes(id),
    FOREIGN KEY (cargo_id) REFERENCES cargos(id),
    FOREIGN KEY (localidade_id) REFERENCES localidades(id)
);

-- =========================================================
-- TRIGGERS
-- =========================================================

DROP TRIGGER IF EXISTS trg_candidato_numero;
DROP TRIGGER IF EXISTS trg_voto_quantidade;
DROP TRIGGER IF EXISTS trg_voto_resultado;


-- ---------------------------------------------------------
-- Valida se o número do candidato possui a quantidade
-- de dígitos definida para o seu cargo
-- ---------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_candidato_numero
BEFORE INSERT ON candidatos
FOR EACH ROW
BEGIN
    DECLARE qtd_digitos INT;

    SELECT quantidade_digitos
    INTO qtd_digitos
    FROM cargos
    WHERE id = NEW.cargo_id;

    IF LENGTH(NEW.numero) <> qtd_digitos THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Número do candidato possui quantidade de dígitos inválida';
    END IF;
END$$

DELIMITER ;


-- ---------------------------------------------------------
-- Impede quantidade de votos igual ou menor que zero
-- ---------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_voto_quantidade
BEFORE INSERT ON votos
FOR EACH ROW
BEGIN
    IF NEW.quantidade_votos <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A quantidade de votos deve ser maior que zero';
    END IF;
END$$

DELIMITER ;


-- ---------------------------------------------------------
-- Ao inserir votos, cria/atualiza o resultado correspondente
-- ---------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_voto_resultado
AFTER INSERT ON votos
FOR EACH ROW
BEGIN
    DECLARE cargo_candidato INT;

    SELECT cargo_id
    INTO cargo_candidato
    FROM candidatos
    WHERE id = NEW.candidato_id;

    IF EXISTS (
        SELECT 1
        FROM resultados
        WHERE eleicao_id = NEW.eleicao_id
          AND cargo_id = cargo_candidato
          AND localidade_id = NEW.localidade_id
    ) THEN

        UPDATE resultados
        SET votos_validos = votos_validos + NEW.quantidade_votos
        WHERE eleicao_id = NEW.eleicao_id
          AND cargo_id = cargo_candidato
          AND localidade_id = NEW.localidade_id;

    ELSE

        INSERT INTO resultados (
            eleicao_id,
            cargo_id,
            localidade_id,
            votos_validos,
            votos_brancos,
            votos_nulos,
            votos_invalidados
        )
        VALUES (
            NEW.eleicao_id,
            cargo_candidato,
            NEW.localidade_id,
            NEW.quantidade_votos,
            0,
            0,
            0
        );

    END IF;
END$$

DELIMITER ;


-- =========================================================
-- FUNCTIONS
-- =========================================================

DROP FUNCTION IF EXISTS VOTAR;

DELIMITER $$
CREATE FUNCTION VOTAR(INT CANDIDATONUMERO, INT ELEITORCPF) RETURNS VARCHAR(32)
BEGIN
	DECLARE LCANDIDATONUMERO INT;
	DECLARE LELEITORCPF CHAR(11);
	DECLARE LVOTOU BOOL;
	
	-- VALIDA SE O CANDIDATO EXISTE
	SELECT NUMERO INTO LCANDIDATONUMERO FROM CANDIDATOS WHERE NUMERO=PCANDIDATONUMERO;
	IF COALESCE (LCANDIDATONUMERO, 0) = 0 THEN
		RETURN 'ESTE CANDIDATO NN EXISTE, NN COMPUTADO';
	END IF;
	-- VALIDAR SE O ELEITOR EXISTE
	
	SELECT CPF INTO LELEITORCPF FROM ELEITORES WHERE CPF=PELEITORCPF;
	IF COALESCE (LCANDIDATONUMERO, 0) = 0 THEN
		RETURN 'ESTE ELEITOR NN EXISTE, NN COMPUTADO';
	END IF;
	
	-- VALIDAR SE JA VOTOU
	
	SELECT VOTOU INTO LVOTOU FROM ELEITORES WHERE CPF=PELEITORCPF;
	IF COALESCE(LVOTOU, FALSE )
	
	-- COMPUTAR VOTO
	
	UPDATE ELEITORES SET VOTOU=TRUE WHERE CPF=PELEITORCPF 
	INSERT INTO VOTOS(NUMERO) VALUES (PCANDIDATONUMERO)
	RETURN 'VOTO COMPUTADO COM SUCESSO'
END$$
DELIMITER; 
-- =========================================================
-- PARTIDOS
-- =========================================================

INSERT INTO partidos (nome, sigla, numero) VALUES
('Partido da Esperança', 'PE', '10'),
('Partido Nacional', 'PN', '20'),
('Partido Popular', 'PP', '30'),
('Partido Democrático', 'PD', '40');


-- =========================================================
-- CARGOS
-- =========================================================

INSERT INTO cargos (nome_cargo, quantidade_digitos) VALUES
('Presidente', 2),
('Governador', 2),
('Senador', 3),
('Deputado Federal', 4),
('Deputado Estadual', 5),
('Vereador', 5);


-- =========================================================
-- LOCALIDADES
-- =========================================================

INSERT INTO localidades (uf, cidade, regiao) VALUES
('RS', 'Novo Hamburgo', 'Sul'),
('RS', 'Porto Alegre', 'Sul'),
('SC', 'Florianópolis', 'Sul'),
('PR', 'Curitiba', 'Sul'),
('SP', 'São Paulo', 'Sudeste');


-- =========================================================
-- ELEIÇÕES
-- =========================================================

INSERT INTO eleicoes (ano, tipo) VALUES
(2026, 'Eleições Gerais'),
(2028, 'Eleições Municipais');


-- =========================================================
-- ZONAS
-- =========================================================

INSERT INTO zonas (numero, localidade_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 3),
(5, 4),
(6, 5);


-- =========================================================
-- SEÇÕES
-- =========================================================

INSERT INTO secoes (numero, zona_id) VALUES
(1, 1),
(2, 1),
(3, 1),
(1, 2),
(2, 2),
(1, 3),
(2, 3),
(1, 4),
(1, 5),
(1, 6);


-- =========================================================
-- CANDIDATOS
-- =========================================================

INSERT INTO candidatos (
    nome,
    numero,
    partido_id,
    cargo_id
) VALUES
('Carlos Almeida', '10', 1, 1),
('João Martins', '20', 2, 1),
('Pedro Souza', '30', 3, 1),

('Marcos Oliveira', '11', 1, 2),
('Rafael Santos', '22', 2, 2),

('Ana Costa', '101', 1, 3),
('Bruno Lima', '202', 2, 3),

('Lucas Pereira', '1010', 1, 4),
('Gabriel Rocha', '2020', 2, 4),

('Mateus Silva', '12345', 3, 5),
('Felipe Gomes', '54321', 4, 5),

('Gustavo Alves', '11111', 1, 6),
('Ricardo Dias', '22222', 2, 6);


-- =========================================================
-- ELEITORES
-- =========================================================

INSERT INTO eleitores (
    nome,
    cpf,
    titulo,
    data_nascimento,
    secao_id,
    votou
) VALUES
('Guilherme Silva', '11111111101', '100000000001', '2000-05-10', 1, FALSE),
('Lucas Pereira', '11111111102', '100000000002', '1998-08-22', 1, FALSE),
('Mariana Costa', '11111111103', '100000000003', '2001-03-15', 2, FALSE),
('João Oliveira', '11111111104', '100000000004', '1995-11-30', 2, FALSE),
('Ana Martins', '11111111105', '100000000005', '2002-07-19', 3, FALSE);


-- =========================================================
-- VOTOS
-- =========================================================

INSERT INTO votos (
    eleicao_id,
    candidato_id,
    localidade_id,
    quantidade_votos
) VALUES
(1, 1, 1, 150),
(1, 2, 1, 120),
(1, 3, 1, 80),

(1, 4, 1, 130),
(1, 5, 1, 110),

(1, 6, 1, 90),
(1, 7, 1, 70),

(1, 8, 1, 200),
(1, 9, 1, 150);
-- =========================
-- TRIGGERS
-- =========================

DROP TRIGGER IF EXISTS verifica_numero_candidato;
DROP TRIGGER IF EXISTS verifica_quantidade_votos;


DELIMITER $$

CREATE TRIGGER verifica_numero_candidato
BEFORE INSERT ON candidatos
FOR EACH ROW
BEGIN
    DECLARE qtd INT;

    SELECT quantidade_digitos
    INTO qtd
    FROM cargos
    WHERE id = NEW.cargo_id;

    IF LENGTH(NEW.numero) <> qtd THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Número do candidato inválido para este cargo';
    END IF;
END$$

DELIMITER ;


DELIMITER $$

CREATE TRIGGER verifica_quantidade_votos
BEFORE INSERT ON votos
FOR EACH ROW
BEGIN
    IF NEW.quantidade_votos < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'A quantidade de votos não pode ser negativa';
    END IF;
END$$

DELIMITER ;
