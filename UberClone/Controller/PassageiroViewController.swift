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

    @IBOutlet var mapa: MKMapView!
    var gerenciadorLocal: CLLocationManager = CLLocationManager()
    
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
            
        } catch {
            print("Erro ao deslogar da conta.")
        }
    }
    
    @IBAction func chamarUberBotao(_ sender: Any) {
        let bancoDados = Database.database().reference()
        let requisicao = bancoDados.child("Requisicoes")
        let autenticacao = Auth.auth()
        guard let localizacao = localizacaoAtualUsuario else {fatalError("Não foi possível obter a localização do usuário.")}
        if let emailUsuario = autenticacao.currentUser?.email {
            let dados: [String: Any] = [
                "Email": emailUsuario,
                "Nome": "Jamile",
                "Longitude": localizacao.longitude,
                "latitude": localizacao.latitude,
            ]
            requisicao.childByAutoId().setValue(dados)
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
    
     
}
