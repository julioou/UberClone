//
//  EntrarViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/11/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import FirebaseAuth

class EntrarViewController: UIViewController {
    
    @IBOutlet var emailLabel: UITextField!
    @IBOutlet var senhaLabel: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func entrarBotao(_ sender: Any) {
        let retorno = self.validarCampo()
        if retorno == "Cadastrado" {
            
            guard let email = emailLabel.text else {fatalError()}
            guard let senha = senhaLabel.text else {fatalError()}
            let autenticacao = Auth.auth()
            
            autenticacao.signIn(withEmail: email, password: senha) { (usuario, erro) in
                if erro == nil {
                    if usuario == nil {
                        print("*********************************")
                        print("Não foi possivel se conectar.")
                        print("*********************************")
                    }
                    
                } else {
                    print("*********************************")
                    print("Falha ao logar conta de usuário.")
                    print("*********************************")
                }
                
            }
            
        } else {
            print("*****************************************")
            print("O campo \(retorno) não foi preenchido.")
            print("*****************************************")
        }
    }
    
    func validarCampo() -> String {
        if emailLabel.text!.isEmpty {
            return "Campo vázio em E-mail"
        } else if senhaLabel.text!.isEmpty {
            return "Campo vázio em Senha"
        }
        
        return "Cadastrado"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
}
