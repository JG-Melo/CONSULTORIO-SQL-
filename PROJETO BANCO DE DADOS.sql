create database Pronto_AT;
use Pronto_AT;

-- tabelas 
create table Doutor (
 id_doc int primary key,
 nome varchar (50) not null,
 Espec varchar (100) not null,
 CRM varchar(20) not null,
 telefone decimal (11) not null
 );
 
create table Paciente (
id_pac int UNIQUE,
nome varchar (50) not null,
telefone decimal (11) not null,
CPF varchar (15) not null,
endereço varchar (50) not null,
alergico varchar(50) not null,
convenio varchar(50) not null,
data_nasc date not null
);

create table Status_consulta (
id_doc int not null,
id_pac int not null,
P_status varchar(50),
foreign key (id_pac) references Paciente(id_pac)
);

create table Consulta (
  id int primary key,
  hora_entrada time not null,
  prioridade varchar(100) not null,
  data_consulta date not null,
  id_doc int not null,
  id_pac int not null,
  foreign key (id_doc)
  references Doutor(id_doc),
  foreign key (id_pac)
  references Paciente(id_pac)
  );

-- adição de dados nas tabelas 
INSERT INTO Doutor VALUES (1,'J.Guilherme','Clinico geral','CRM-SP 223344', 11933445252);
INSERT INTO Doutor VALUES (3,'Matheus Costa','Cardiologista','CRM-MT 334422', 11444777231);
INSERT INTO Doutor VALUES (12,'Augusto Lemes','Clinico geral','CRM-MG 123654', 13245678812);
INSERT INTO Doutor VALUES (5,'Bruno Almeida', 'Ginecologista', 'CRM-SP 345890', 11342612278);

INSERT INTO Paciente VALUES (2, 'Eric', 11943322788, '222.333.444-55','Rua sei lá', 'não possui alergia', 'possui convenio', '2000-04-11');
INSERT INTO Paciente VALUES (1, 'João Cunha', 11346675789, '345.987.333-22','Rua azul', 'não possui alergia', 'possui convenio','2000-11-02');
INSERT INTO Paciente VALUES (3, 'João Lopez', 12567999087, '513.987.543-89','Rua azul', 'não possui alergia','não possui convenio','1987-12-07');
INSERT INTO Paciente VALUES (7, 'Vanessa Lopez', 11509123456, '409.655.345-90','Rua verde', 'não possui alergia', 'possui convenio', '2003-02-27');

INSERT INTO Consulta VALUES (15, '12:23:00', 'urgente', '2025-04-30', 1, 2);
INSERT INTO Consulta VALUES (10, '10:12:00', 'baixa urg', '2025-04-29', 3, 1);
INSERT INTO Consulta VALUES (14, '09:14:00','média urg', '2025-04-27', 12,3);
INSERT INTO Consulta VALUES (22, '07:02:00','baixa urg', '2025-04-07', 5, 7);

INSERT INTO Status_consulta VALUES (1, 2, 'Concluida');
INSERT INTO Status_consulta VALUES (3, 1, 'Concluida');
INSERT INTO Status_consulta VALUES (12, 3, 'Em progresso');
INSERT INTO Status_consulta VALUES (5, 7, 'Concluida');

-- algumas alterações entre as etapas
alter table Status_consulta 
add column Comentários text not null;

alter table Doutor add column ativo TINYINT DEFAULT 1;
alter table Paciente add column ativo TINYINT DEFAULT 1;
alter table Status_consulta add column ativo TINYINT DEFAULT 1;
alter table Consulta add column ativo TINYINT DEFAULT 1;

update Status_consulta
set Comentários= 'Paciente chegou com quadro crítico e foi rapidamente estabilizado. Encaminhado pra exames e
segue em observação.'
where id_doc=1;

update Status_consulta
set Comentários= 'Paciente apresentou sintomas leves, orientado a manter acompanhamento e retorno em caso de piora.'
where id_doc=3;

update Status_consulta
set Comentários= 'Paciente com sintomas moderados, foi medicado e segue em observação.'
where id_doc=12;

update Status_consulta
set Comentários= 'Paciente com queixas leves, exames realizados e liberada com orientações.'
where id_doc=5;

alter table Status_consulta
add column id_status int primary key auto_increment;


-- Para ver os comentarios de forma organizada com nomes
select d.nome as nome_Doutor,
p.nome as nome_paciente, sc.comentarios
from Status_consulta sc
join Doutor d on d.id_doc = sc.id_doc
join Paciente p on p.id_pac = sc.id_pac
order by sc.P_status;

-- View para visualizar pacientes idosos:
CREATE VIEW pacientes_idosos AS SELECT nome, data_nasc, timestampdiff(year, data_nasc, CURDATE()) as idade from Paciente 
Where timestampdiff(year, data_nasc, CURDATE()) >= 60;

-- View atendimento por médico(no dia atual):
CREATE VIEW consulta_medico_hoje AS select d.nome as nome, COUNT(C.id) as total_consultas
from Consulta c
join Doutor d on C.id_doc = d.id_doc
where date (c.data_consulta) = CURDATE() group by d.nome;

-- View para filtrar o grau de urgencia de atendimento dos pacientes;
CREATE VIEW grau_de_urgencia AS SELECT p.nome, t.prioridade, t.hora_entrada, timestampdiff(MINUTE, t.hora_entrada, NOW()) as minutos_espera
from Consulta t 
join Paciente p on t.id_pac = p.id_pac
order by t.prioridade DESC;

-- View para ver a fila de espera atual
CREATE VIEW fila_espera AS SELECT p.nome, t.prioridade, t.hora_entrada, timestampdiff(MINUTE, t.hora_entrada, NOW()) as minutos_espera 
from Consulta t 
join Paciente p on t.id_pac = t.id_pac
left join Consulta c on t.id_pac = c.id_pac
where c.id_pac IS NULL
order by t.prioridade DESC, t.hora_entrada ASC;


-- Indices
create INDEX Doc_nome on Doutor(nome, CRM);

select * from Doutor where nome = "J.Guilherme";

create INDEX idx_pac_dados on Paciente(nome, CPF, data_nasc);

select  nome , CPF, data_nasc from Paciente where nome = "Eric";

create INDEX idx_consulta on Consulta(hora_entrada, prioridade, data_consulta);

select * from Consulta where prioridade = "baixa urg"; 

-- Procedures(com as transações) 

-- inclusão de novos dados
DELIMITER //
create procedure InserirDoutor (
in p_id_doc int, 
in p_nome varchar(50),
in p_espec varchar(50),
in p_CRM varchar(50),
in p_telefone decimal(11)
)
begin 
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
insert into Doutor(id_doc, nome, espec, CRM, telefone,ativo)
values (p_id_doc, p_nome, p_espec, p_CRM, p_telefone,1);
commit;
end //
DELIMITER ;

DELIMITER //
create procedure InserirPaciente(
in p_id_pac int,
in p_nome varchar(50),
in p_telefone decimal (11),
in p_CPF varchar(15),
in p_endereço varchar(50),
in p_alergico varchar(50),
in p_convenio varchar(50),
in p_data_nasc date
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
insert into Paciente(id_pac, nome, telefone, CPF, endereço, alergico, convenio, data_nasc,ativo)
values (p_id_pac, p_nome, p_telefone, p_CPF, p_endereço, p_alergico, p_convenio, p_data_nasc,1);
commit;
end //
DELIMITER ;

DELIMITER //
create procedure InserirStatusCon(
in p_id_doc int,
in p_id_pac int,
in p_P_status varchar(50)
)
begin 
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
insert into Status_consulta (id_doc, id_pac, P_status,ativo)
values (p_id_doc, p_id_pac, p_P_status,1);
commit;
end //
DELIMITER ;

DELIMITER //
create procedure InserirConsulta(
in p_id int,
in p_hora_entrada time,
in p_prioridade varchar(100),
p_data_consulta date,
p_id_doc int,
p_id_pac int
)
begin 
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
insert into Consulta(id, hora_entrada, prioridade, data_consulta, id_doc, id_pac,ativo)
values (p_id, p_hora_entrada, p_prioridade, p_data_consulta, p_id_doc, p_id_pac,1);
commit;
end //
DELIMITER ;

-- testes 
CALL InserirDoutor(15, 'Marjorie', 'enfermeira', 'CRM-SP 234567', '11456000123');
CALL InserirPaciente(23, 'Felipe Luis', 11943977651, '234.765.111-99', 'rua barão jr', 'não possui alergia', 'possui convenio', '2000-12-11');

select * from Doutor;

-- atualização de dados 
DELIMITER //
create procedure AtualizarDoutor(
in p_id_doc int, 
in p_nome varchar(50),
in p_Espec varchar(100),
in p_CRM varchar(20),
in p_telefone decimal(11)
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Doutor
set nome = p_nome,
Espec = p_Espec,
CRM = p_CRM 
where id_doc = p_id_doc and ativo=1;
commit;
end//
DELIMITER ;

DELIMITER //
create procedure AtualizarPaciente(
in p_id_pac int,
in p_nome varchar(50),
in p_telefone decimal (11,0),
in p_CPF varchar(15),
in p_endereço varchar(50),
in p_alergico varchar(50),
in p_convenio varchar(50),
in p_data_nasc date
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Paciente 
set nome = p_nome,
telefone = p_telefone,
CPF = p_CPF,
endereço = p_endereço,
alergico = p_alergico,
convenio = p_convenio,
data_nasc = p_data_nasc
where id_pac = p_id_pac and ativo=1;
commit;
end //
DELIMITER ;

DELIMITER //
create procedure AtualizarStatusCon(
in p_id_doc int,
in p_id_pac int,
in p_P_status varchar(50),
in p_id_status int
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Status_consulta
set id_doc= p_id_doc,
id_pac= p_id_pac,
P_status = p_P_status
where id_status = p_id_status and ativo =1;
commit;
end //
DELIMITER ;

DELIMITER //
create procedure AtualizarConsulta(
in p_id int,
in p_hora_entrada time,
in p_prioridade varchar(100),
p_data_consulta date,
p_id_doc int,
p_id_pac int
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Consulta 
set hora_entrada = p_hora_entrada,
 prioridade = p_prioridade,
data_consulta = p_data_consulta,
id_doc = p_id_doc,
id_pac = p_id_pac
where id = p_id and ativo= 1;
commit;
end //
DELIMITER ;

-- teste 
Call AtualizarDoutor(1,'Guilherme','cirurgiao','CRM-SP 223344', 11933445252);
Call AtualizarPaciente(2, 'Eric', 11943322788, '222.333.444-55','Rua sei lá', 'não possui alergia', 'possui convenio', '2000-04-11');

-- Exclusão logica de dados

DELIMITER //
create procedure ExcluirDoutor(
in p_id_doc int
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Doutor
set ativo= 0 
where id_doc = p_id_doc and ativo =1;
end //
commit;
DELIMITER ;

DELIMITER //
create procedure ExcluirPaciente(
in p_id_pac int 
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Paciente 
set ativo= 0 
where id_pac = p_id_pac and ativo =1;
end //
commit;
DELIMITER ;

DELIMITER //
create procedure ExcluirStatusCon(
in p_id_status int
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Status_consulta
set ativo=0
where id_status = p_id_status and ativo=1;
end //
commit;
DELIMITER ;

DELIMITER //
create procedure ExcluirConsulta(
in p_id int 
)
begin
declare exit handler for sqlexception
begin
rollback;
end;
start transaction;
update Consulta 
set ativo= 0
where id = p_id and ativo=1;
commit;
end //
DELIMITER ;

-- testes
Call ExcluirDoutor(1);

-- após a exclusão logica, basta usar o update para ativar alguém na tabela denovo
update Doutor 
set ativo=1
where id_doc=1;

select * from Paciente;
select * from Doutor;
select * from Status_Consulta;

























