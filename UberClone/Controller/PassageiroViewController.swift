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
    
    var gerenciadorLocal: CLLocationManager = CLLocationManager();
    var appIniciado: Bool = false
    var uberChamado = false
    var localizacaoAtualUsuario: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
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
    
    @IBAction func chamarUberBotao(_ sender: Any) {
        let autenticacao = Auth.auth()
        if autenticacao.currentUser != nil {
            let bancoDados = Database.database().reference()
            let requisicao = bancoDados.child("Requisicoes")
            guard let localizacao = localizacaoAtualUsuario else {fatalError("Não foi possível obter a localização do usuário.")}
            if let emailUsuario = autenticacao.currentUser?.email {
                if self.uberChamado {
                    //Altenar botão.
                    self.alternarChamar()
                    
                    //Remover requisicão
                    requisicao.queryOrdered(byChild: "Email").queryEqual(toValue: emailUsuario).observeSingleEvent(of: .childAdded) { (snapshot) in
                        requisicao.ref.removeValue()
                    }
                } else {
                    //Recuperar Nome do passageiro.
                    if let uidUsuario = autenticacao.currentUser?.uid {
                        let usuarios = bancoDados.child("Usuarios").child(uidUsuario)
                        usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                            if let dados = snapshot.value as? NSDictionary {
                                let nomeUsuario = dados["Nome"] as? String
                                //Altenar botão.
                                self.alterCancelar()
                                
                                //Salvar dados da requisição.
                                let dadosRequisicao: [String: Any] = [
                                    "Email": emailUsuario,
                                    "Nome": nomeUsuario,
                                    "Longitude": localizacao.longitude,
                                    "Latitude": localizacao.latitude,
                                ]
                                requisicao.childByAutoId().setValue(dadosRequisicao)
                            } else {
                                print("Nao foi possivel aceesar dados do snapshot")
                            }
                        })
                    }
                }
            }
        } else {
            print("Não foi possível acessar o rede.")
        }
    }
    
    //Exibindo a navigation bar assim que a tela aparece.
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    //MARK - Configurando Mapa
    //ATUALIZANDO A POSICAO DO USUARIO.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let localizacaoUsuario = manager.location?.coordinate {
            localizacaoAtualUsuario = localizacaoUsuario
            let regiao = MKCoordinateRegion(center: localizacaoUsuario, latitudinalMeters: 200, longitudinalMeters: 200)
            self.mapa.setRegion(regiao, animated: true)
            //Criar uma anotação no local do usuário.
            let anotacaoUsuario = MKPointAnnotation()
            anotacaoUsuario.coordinate = localizacaoUsuario
            anotacaoUsuario.title = "Seu Local"
            mapa.addAnnotation(anotacaoUsuario)
        }
    }
 
    func alterCancelar(){
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
}
