//
//  PassageiroViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/11/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase
import CoreLocation

class PassageiroViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var botaoChamar: UIButton!
    @IBOutlet var mapa: MKMapView!
    
    @IBOutlet weak var areaEndereco: UIView!
    @IBOutlet weak var campoMeuLocal: UITextField!
    @IBOutlet weak var marcadorMeuLocal: UIView!
    @IBOutlet weak var campoDestino: UITextField!
    @IBOutlet weak var marcadorDestino: UIView!
    
    var gerenciadorLocal: CLLocationManager = CLLocationManager();
    var appIniciado: Bool = false
    var uberChamado = false
    var uberACaminho = false
    var localizacaoAtualUsuario: CLLocationCoordinate2D?
    var localMotorista = CLLocationCoordinate2D()
    
    
    //Exibindo a navigation bar assim que a tela aparece.
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
        
        //Setando estilizacao
        estilizarAreaEndereco()
        
        let dados = Database.database().reference()
        
        //Verificar se ja existe uma requisição ativa.
        if let emailUsuario = Auth.auth().currentUser?.email {
            
            let requisicao = dados.child("Requisicoes")
            let consultaRequisicoes = requisicao.queryOrdered(byChild: "Email").queryEqual(toValue: emailUsuario)
            
            consultaRequisicoes.observe(.childAdded) { (snapshot) in
                if snapshot.value != nil {
                    self.alternarCancelar()
                }
            }
            
            //Verificando se algum motorista aceitou a requisicao.
            consultaRequisicoes.observe(.childChanged) { (snapshot) in //Mudar para childChanged quando for finalizar app
                if let dados = snapshot.value as? [String: Any] {
                    
                    if let latMotorista = dados["MotoristaLatitude"] {
                        if let longMotorista = dados["MotoristaLongitude"] {
                            
                            self.localMotorista = CLLocationCoordinate2D(latitude: latMotorista as! CLLocationDegrees, longitude: longMotorista as! CLLocationDegrees)
                            self.exibirMotoristaPassageiro()
                        }
                    }
                }
            }
        }
    }
    
    func exibirMotoristaPassageiro() {
        //Setando uber a camminho
        self.uberACaminho = true
        //Tratando o nill do localizcaoAtualUsuario
        guard let localPassageiro = localizacaoAtualUsuario else {fatalError()}
        
        //Calcular distancia entre passageiro e motorista.
        let localizacaoPassageiro = CLLocation(latitude: localPassageiro.latitude, longitude: localPassageiro.longitude)
        let localizacaoMotorista = CLLocation(latitude: localMotorista.latitude, longitude: localMotorista.longitude)
        
        //Formatando numero para obter distancia mais aproximada
        let distancia = localizacaoMotorista.distance(from: localizacaoPassageiro)
        let distanciaFinal = NSNumber(value: distancia / 100)
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
        formatter.maximumFractionDigits = 3
        if let roundedValue = formatter.string(from: distanciaFinal) {
            //Trabalhando com o desing do botao chamar uber.
            botaoACaminho(texto: roundedValue)
        }
        
        //Exibir passageiro e motorista no mapa.
        mapa.removeAnnotations(mapa.annotations)
        let latDiferenca = abs(localPassageiro.latitude - self.localMotorista.latitude) * 300_000
        let longDiferenca = abs(localPassageiro.longitude - self.localMotorista.longitude) * 300_000
        let regiao = MKCoordinateRegion(center: localPassageiro, latitudinalMeters: latDiferenca, longitudinalMeters: longDiferenca)
        mapa.setRegion(regiao, animated: true)
        
        //Anotacao motorista
        let anotacaoMotorista = MKPointAnnotation()
        anotacaoMotorista.coordinate = self.localMotorista
        anotacaoMotorista.title = "Motorista"
        mapa.addAnnotation(anotacaoMotorista)
        
        //Anotacao passageiro
        
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = localPassageiro
        anotacaoPassageiro.title = "Passageiro"
        mapa.addAnnotation(anotacaoPassageiro)
        
    }
    
    //Funcao para sair do conta do usuario.
    @IBAction func sairBotao(_ sender: Any) {
        let autenticacao = Auth.auth()
        do {
            try autenticacao.signOut()
            print("Deslogado com sucesso!")
            dismiss(animated: true, completion: nil)
        } catch {
            print("Erro ao deslogar da conta.")
        }
    }
    //MARK: - BOTAO CHAMAR
    @IBAction func chamarUberBotao(_ sender: Any) {
        let autenticacao = Auth.auth()
        let bancoDados = Database.database().reference()
        let requisicao = bancoDados.child("Requisicoes")
        
        if autenticacao.currentUser != nil {
            if let localizacao = localizacaoAtualUsuario {
                if let emailUsuario = autenticacao.currentUser?.email {
                    if self.uberChamado { //Remover requisicao do uber
                        //Altenar botão.
                        self.alternarChamar()
                        //Remover requisicão
                        requisicao.queryOrdered(byChild: "Email").queryEqual(toValue: emailUsuario).observeSingleEvent(of: .childAdded) { (snapshot) in
                            snapshot.ref.removeValue()
                        }
                        
                    } else { //Uber nao foi chamado
                        
                        //Receber requisicao e salvar
                        //                        salvarRequisicao(autenticacaoP: autenticacao, bancoDadosP: bancoDados, emailUsuarioP: emailUsuario, localizacaoP: localizacao);
                        if let enderecoDestino = self.campoDestino.text {
                            if enderecoDestino != "" {
                                CLGeocoder().geocodeAddressString(enderecoDestino, completionHandler: { (local, erro) in
                                    if erro == nil {
                                        if let destinoLocal = local?.first {
                                            let dadosEndereco = self.verificacaoEndereco(local: local)
                                            
                                            if let latDestino = destinoLocal.location?.coordinate.latitude{
                                                if let lonDestino = destinoLocal.location?.coordinate.longitude{
                                                    
                                                    let alerta = UIAlertController(title: "Confirme seu endereço!", message: dadosEndereco, preferredStyle: .alert)
                                                    
                                                    let acaoCancelar = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                                                    
                                                    let acaoConfirmar = UIAlertAction(title: "Confirmar", style: .default, handler: { (alertAction) in
                                                        
                                                        //Recuperar nome usuario
                                                        let idUsuario = autenticacao.currentUser?.uid
                                                        let usuarios = bancoDados.child("Usuarios").child(idUsuario!)
                                                        
                                                        usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                                                            
                                                            let dados = snapshot.value as? NSDictionary
                                                            
                                                            let nomeUsuario = dados!["Nome"] as? String
                                                            
                                                            //alternar para o botao de cancelar
                                                            self.alternarCancelar()
                                                            
                                                            //Salvar dados da requisicao
                                                            let dadosUsuario = [
                                                                "DestinoLatitude" : latDestino ,
                                                                "DestinoLongitude" : lonDestino ,
                                                                "Email" : emailUsuario,
                                                                "Nome" : nomeUsuario,
                                                                "Latitude" : self.localizacaoAtualUsuario!.latitude,
                                                                "Longitude" : self.localizacaoAtualUsuario!.longitude
                                                                ] as [String : Any]
                                                            requisicao.childByAutoId().setValue( dadosUsuario )
                                                            
                                                            self.alternarCancelar()
                                                            
                                                        })
                                                        
                                                    })
                                                    
                                                    alerta.addAction(acaoCancelar)
                                                    alerta.addAction(acaoConfirmar)
                                                    
                                                    self.present(alerta, animated: true, completion: nil)
                                                    
                                                }//fim lonDestino
                                                
                                            }//fim latDestino
                                        }
                                    }
                                }) //Fim CLGeocoder
                            }
                        }
                    }
                }
            }
            else {
                print("Não foi possível acessar o rede.")
            }
        }
    }
    
    func verificacaoEndereco(local: [CLPlacemark]?) -> String {
        var enderecoCompleto = ""
        let local = local!
        if let dadosLocal = local.first {
            var rua = ""
            if dadosLocal.thoroughfare != nil {
                rua = dadosLocal.thoroughfare!
            }
            
            var numero = ""
            if dadosLocal.subThoroughfare != nil {
                numero = dadosLocal.subThoroughfare!
            }
            
            var bairro = ""
            if dadosLocal.subLocality != nil {
                bairro = dadosLocal.subLocality!
            }
            
            var cidade = ""
            if dadosLocal.locality != nil {
                cidade = dadosLocal.locality!
            }
            
            var cep = ""
            if dadosLocal.postalCode != nil {
                cep = dadosLocal.postalCode!
            }
            enderecoCompleto = "\(rua), \(numero), \(bairro) - \(cidade) - \(cep)"
            return enderecoCompleto
        }
        return enderecoCompleto
    }
    
    func salvarRequisicao(autenticacaoP: Auth, bancoDadosP: DatabaseReference, emailUsuarioP: String, localizacaoP: CLLocationCoordinate2D) {
        //Recuperar Nome do passageiro.
        if let uidUsuario = autenticacaoP.currentUser?.uid {
            let usuarios = bancoDadosP.child("Usuarios").child(uidUsuario)
            usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                if let dados = snapshot.value as? NSDictionary {
                    if let nomeUsuario = dados["Nome"] as? String {
                        //Altenar botão.
                        self.alternarCancelar()
                        
                        //Salvar dados da requisição.
                        let dadosRequisicao: [String: Any] = [
                            "Email": emailUsuarioP,
                            "Nome": nomeUsuario,
                            "Longitude": localizacaoP.longitude,
                            "Latitude": localizacaoP.latitude,
                        ]
                        bancoDadosP.child("Requisicoes").childByAutoId().setValue(dadosRequisicao)
                    }
                }
                else {
                    print("Nao foi possivel aceesar dados do snapshot")
                }
            }) //Fim da closure observe single event.
        }
    }
    
    //MARK: - CONFIGURANDO MAPA
    //ATUALIZANDO A POSICAO DO USUARIO.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let localizacaoUsuario = manager.location?.coordinate {
            localizacaoAtualUsuario = localizacaoUsuario
            
            if self.uberACaminho {
                self.exibirMotoristaPassageiro()
            } else {
                let regiao = MKCoordinateRegion(center: localizacaoUsuario, latitudinalMeters: 200, longitudinalMeters: 200)
                self.mapa.setRegion(regiao, animated: true)
                //Criar uma anotação no local do usuário.
                let anotacaoUsuario = MKPointAnnotation()
                anotacaoUsuario.coordinate = localizacaoUsuario
                anotacaoUsuario.title = "Seu Local"
                mapa.addAnnotation(anotacaoUsuario)
            }
        }
    }
    
    //MARK: - CONFIGURANDO ESTILO
    func alternarCancelar(){
        let texto = "Cancelar Uber";
        self.botaoChamar.setTitle(texto, for: .normal)
        self.botaoChamar.backgroundColor = UIColor(displayP3Red: 0.831, green: 0.231, blue: 0.146, alpha: 1)
        self.uberChamado = true
        print(texto)
    }
    
    func alternarChamar() {
        let texto = "Chamar Uber";
        self.botaoChamar.setTitle(texto, for: .normal)
        self.botaoChamar.backgroundColor = UIColor(red: 3/255, green: 116/255, blue: 125/255, alpha: 1.0)
        self.uberChamado = false
        print(texto)
    }
    
    func botaoACaminho(texto: String) {
        self.botaoChamar.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoChamar.setTitle("Motorista \(texto) KM distante", for: .normal)
    }
    
    func estilizarAreaEndereco() {
        // Area Endereco
        areaEndereco.layer.cornerRadius = 15
        areaEndereco.clipsToBounds = true
        // Marcador Destino
        marcadorDestino.layer.cornerRadius = 7.5
        marcadorDestino.clipsToBounds = true
        // Marcador MeuLocal
        marcadorMeuLocal.layer.cornerRadius = 7.5
        marcadorDestino.clipsToBounds = true
    }

}
