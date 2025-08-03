// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract contrato{
    address owner;
    mapping(address => bool) public esValidador;
    uint256 public contadorOperaciones = 0;

    enum Rol { Importador, Exportador }
    enum Estado { Pendiente, Validado, Imcompleto }

    struct Usuario {
        string nombre;
        Rol rol;
        uint256 reputacion;
        bool registrado;
    }
    struct Operacion{
        address importador;
        address exportador;
        uint256 monto;
        Estado estado; 
    }
    
    mapping(address => Usuario) usuarios;
    mapping(uint256 => Operacion) public operaciones;
    mapping(address => uint[]) opUsuarios;

    event Registro(string indexed nombre,Rol rol);
    event nuevaOperacion(address importador,address exportador,uint256 monto);

    constructor(){
        owner=payable(msg.sender);
    }
    function registrarValidador(address validador)public{
        require(msg.sender == owner);
        esValidador[msg.sender]= true;
    }

    function registro(string memory nombre,Rol rol) external {
        require(!usuarios[msg.sender].registrado,"adress ya esta registrado registrado");
        usuarios[msg.sender]=Usuario(nombre,rol,0,true);
        emit Registro(nombre,rol);
    }

    function hacerPedido(address exportador) payable public{
        require(usuarios[msg.sender].registrado,"adress no registrado");
        require(usuarios[msg.sender].rol==Rol.Importador,"adress registrado como exportador");

        Operacion memory op=Operacion(msg.sender,exportador,msg.value,Estado.Pendiente);
        contadorOperaciones +=1;
        operaciones[contadorOperaciones]=op;
        opUsuarios[msg.sender].push(contadorOperaciones);
        emit nuevaOperacion(msg.sender,exportador,msg.value);
    }
    function validar()external{        
        require(esValidador[msg.sender], "No eres un validador autorizado");



    }
    function pagarAExportador(uint256 id)private{
        address exportador=operaciones[id].exportador;




    }

}