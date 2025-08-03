// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract contrato is ReentrancyGuard{
    address owner;
    mapping(address => bool) public esIntermediario;
    uint256 public contadorOperaciones = 0;
    uint256 porcentajeComision;
    uint256 ganancia=0;

    enum Estado { Pendiente, exitoso, enDisputa,resuelto}
    enum TipoDeExportador{intermediario,productor}

    struct Exportador {
        string nombreComercial;
        string codigoDeComercio;
        string nombreRepresntante;
        string producto;
        TipoDeExportador tipoE;
        uint256 reputacion;
        bool registrado;
    }
    struct Importador{
        string nombreEmpresa;
        string nombreRepresentante;
        uint256 reputacion;
        bool registrado;
        
    }
    struct Operacion{
        address importador;
        address exportador;
        uint256 monto;
        Estado estado;
    }
    
    mapping(address => Exportador) exportadores;
    mapping(address => Importador) importadores;
    mapping(uint256 => Operacion) public operaciones;
    mapping(address => uint[]) opUsuarios;
    address[] intermediarios;

    event Registro(string indexed nombre,string tipo);
    event nuevaOperacion(address importador,address exportador,uint256 monto);
    event OperacionExitosa(uint256 id);
    event DisputaResuelta(uint256 indexed id, address ganador, address intermediario);


    error noSePundoRealizarTransaccion();
    constructor(){
        owner=payable(msg.sender);
        porcentajeComision = 5;
    }
    function registrarIntermediario(address validador)public{
        require(msg.sender == owner);
        esIntermediario[validador] = true;
    }

    function registroImportador(
        string memory nombreEmpresa,string memory Representante) external {
        require(!importadores[msg.sender].registrado, "Ya registrado");
        importadores[msg.sender] = Importador(nombreEmpresa,Representante,0,true);
        
        emit Registro(nombreEmpresa,"Importador");
    }
    function registroExportador(
        string memory nombreEmpresa,string memory codigoDeComercio,string memory Representante,string memory producto
        ,TipoDeExportador tipoE) external {
        require(!exportadores[msg.sender].registrado, "Ya registrado");
        exportadores[msg.sender] = Exportador(nombreEmpresa,codigoDeComercio,Representante,producto,tipoE,0,true);
        
        emit Registro(nombreEmpresa,"Exportador");
    }

    function hacerPedido(address exportador) payable public{
        require(importadores[msg.sender].registrado,"adress no registrado como importador");

        Operacion memory op=Operacion(msg.sender,exportador,msg.value,Estado.Pendiente);
        contadorOperaciones +=1;
        operaciones[contadorOperaciones]=op;
        opUsuarios[msg.sender].push(contadorOperaciones);
        emit nuevaOperacion(msg.sender,exportador,msg.value);

    }
    function validar(uint256 id)external{      
        require(msg.sender==operaciones[id].importador, "No tienes permiso para validar ");
        address exportador=operaciones[id].exportador;
        exportadores[exportador].reputacion+=1;

        address importador=operaciones[id].importador;
        importadores[importador].reputacion += 1;

        pagar(id,exportador);
        operaciones[id].estado = Estado.exitoso;

        emit OperacionExitosa(id);
    }

    function mediar(uint256 id,address ganador)public {
        require(esIntermediario[msg.sender],"no es intermediario");
        require(operaciones[id].estado==Estado.enDisputa,"la operacion no esta en disputa");
        require(operaciones[id].exportador==ganador|| operaciones[id].importador==ganador,
        "ganador no participa en operacion");
        pagar(id,ganador);
        operaciones[id].estado = Estado.resuelto;
        emit DisputaResuelta(id, ganador, msg.sender);


    }

    function pagar(uint256 id,address venefisiario)private nonReentrant{
        require(operaciones[id].exportador==venefisiario || operaciones[id].importador==venefisiario,
        "veneficiario no participa en operacion");
        uint256 montoTransacion=operaciones[id].monto;
        uint256 comicion = (montoTransacion * porcentajeComision)/100;
        uint256 montoAEnviar=montoTransacion-comicion;
        ganancia+=comicion;
        (bool sent,)=payable (venefisiario).call{value: montoAEnviar}("");
        if (!sent){
            revert noSePundoRealizarTransaccion();
        }
    }
    function operacionesDe(address usuario) public view returns (uint[] memory) {
        return opUsuarios[usuario];
    }

}