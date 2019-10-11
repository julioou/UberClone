//
//  ViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/11/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import FirebaseAuth

class PrincipalViewController: UIViewController {

    let autenticacao = Auth.auth()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        autenticacao.addStateDidChangeListener { (autenticacao, usuario) in
            if let usuarioLogado = usuario {
                self.performSegue(withIdentifier: "menuGo", sender: nil)
            }
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }

}

