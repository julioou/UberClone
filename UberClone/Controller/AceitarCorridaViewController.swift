//
//  AceitarCorridaViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/24/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase
import FirebaseAuth

class AceitarCorridaViewController: UIViewController, CLLocationManagerDelegate  {

    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaoAceitarCorrida: UIButton!
    var corridaAceita: Bool = false
    
    //Atributos do passageiro e motorista
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localizacaoPassageiro = CLLocationCoordinate2D()
    var localizacaoMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Centralizando câmera.
        let regiao = MKCoordinateRegion(center: localizacaoPassageiro, latitudinalMeters: 200, longitudinalMeters: 200)
        mapa.setRegion(regiao, animated: true)
        
        //Adicionado marcacao
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localizacaoPassageiro
        anotacaoPassageiro.title = nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
        
    }

    @IBAction func botaoAceitar(_ sender: Any) {
        
        //Att requisicao com localidade do motorista
        attDadosMotorista()
        
        let passageiroCLL = CLLocation(latitude: localizacaoPassageiro.latitude, longitude: localizacaoPassageiro.longitude)
        CLGeocoder().reverseGeocodeLocation(passageiroCLL) { (local, erro) in
            if erro == nil {
                if let dadosLocal = local?.first {
                    let placeMark = MKPlacemark(placemark: dadosLocal)
                    let mapaItem = MKMapItem(placemark: placeMark)
                    mapaItem.name = self.nomePassageiro
                    
                    let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault]
                    mapaItem.openInMaps(launchOptions: opcoes)
                }
            } else {
                print("Erro ao criar rota.")
            }
        }
        
        if corridaAceita == false {
            alternarBotaoAceito()
            print("false")
        } else {
            alternarBotaoNaoAceito()
            print("true")
        }
    }
    
    func alternarBotaoAceito() {
        botaoAceitarCorrida.backgroundColor = UIColor(red: 3/255, green: 116/255, blue: 125/255, alpha: 1.0)
        self.corridaAceita = true
        print("Aceito")
    }
    
    func alternarBotaoNaoAceito() {
        botaoAceitarCorrida.backgroundColor = UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 1.0)
        self.corridaAceita = false
    }
    
    func attDadosMotorista() {
        //Atualizar a requisicao
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        let requisicoes = database.child("Requisicoes")
        
        if let emailMotorista = autenticacao.currentUser?.email {
            requisicoes.queryOrdered(byChild: "Email").queryEqual(toValue: self.emailPassageiro ).observeSingleEvent(of: .childAdded) { (snapshot) in
                let dadosMotorista = [
                    "MotoristaEmail" : emailMotorista,
                    "MotoristaLatitude" : self.localizacaoMotorista.latitude,
                    "MotoristaLongitude" : self.localizacaoMotorista.longitude
                    ] as [String : Any]
                snapshot.ref.updateChildValues(dadosMotorista)
            }
        }
    }
}
