//
//  CadastroViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/11/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import FirebaseAuth

class CadastroViewController: UIViewController {

    @IBOutlet var emailLabel: UITextField!
    @IBOutlet var nomeLabel: UITextField!
    @IBOutlet var senhaLabel: UITextField!
    @IBOutlet var tipoUsuario: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //Validar campos se certificando que o usuario nao deixou nenhum campo em branco.
    func validarCampos() -> String {
        if emailLabel.text!.isEmpty {
            return "Campo vázio em E-mail"
        } else if nomeLabel.text!.isEmpty {
            return "Campo vázio em Nome Completo"
        } else if senhaLabel.text!.isEmpty {
            return "Campo vázio em Senha"
        }
        
        return "Cadastrado"
    }
    
    //Botao para executar acoes
    @IBAction func cadastrarBotao(_ sender: Any) {
        let retorno = self.validarCampos()
        if retorno == "Cadastrado" {
            
            guard let email = emailLabel.text else {fatalError()}
            guard let senha = emailLabel.text else {fatalError()}
            let autenticacao = Auth.auth()
            
            autenticacao.createUser(withEmail: email, password: senha) { (usuario, erro) in
                if erro == nil {
                    if usuario != nil {
                        self.performSegue(withIdentifier: "cadastroGo", sender: nil)
                    }
                } else {
                    print("Erro ao criar conta de usuário.")
                }
            }
            
            
        } else {
            print("O campo \(retorno) não foi preenchido.")
        }
    }
    
    //Funcao para minimizar o teclado assim que se tocar em qualquer lugar da tela.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    //Funcao que é chamada sempre que a tela vai aparecer.
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }


}
