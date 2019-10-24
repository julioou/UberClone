//
//  ViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/11/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class PrincipalViewController: UIViewController {

    let autenticacao = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autenticacao.addStateDidChangeListener { (autenticacao, usuario) in
            if let usuarioLogado = usuario {
                let bancoDados = Database.database().reference()
                let usuarioRef = bancoDados.child("Usuarios").child(usuarioLogado.uid)
                
                usuarioRef.observeSingleEvent(of: .value) { (snapshot) in
                    let dados = snapshot.value as? NSDictionary
                    let tipoUsuario = dados!["Tipo"] as! String

                    if tipoUsuario == "Passageiro" {
                        self.performSegue(withIdentifier: "menuGo", sender: nil)
                    } else {
                        self.performSegue(withIdentifier: "motoristaGo", sender: nil)
                    }
                }
                
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

}

