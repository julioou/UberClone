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

class PassageiroViewController: UIViewController {

    @IBOutlet var mapa: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //Funcao para sair do conta do usuario.
    @IBAction func sairBotao(_ sender: Any) {
        let autenticacao = Auth.auth()
        do {
            try autenticacao.signOut()
            self.performSegue(withIdentifier: "menuGo", sender: nil)
        } catch {
            print("Erro ao deslogar da conta.")
        }
    }
    
    @IBAction func chamarUberBotao(_ sender: Any) {
        
    }
    
    //Exibindo a navigation bar assim que a tela aparece.
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
}
