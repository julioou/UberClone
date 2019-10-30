//
//  MotoristaTableViewController.swift
//  UberClone
//
//  Created by Treinamento on 10/22/19.
//  Copyright © 2019 JCAS. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseAuth
import FirebaseDatabase

class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate {
    //Store data
    var listaRequisicoes : [DataSnapshot] = []
    
    //Lidando com o GPS
    var gerenciadorLocal: CLLocationManager = CLLocationManager();
    var localizacaodoMotorista: CLLocationCoordinate2D?
    let segueVaiParaAceitarCorrida = "VaiAceitarCorrida"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Configurando localizacao do motorista.
        gerenciadorLocal.delegate = self
        gerenciadorLocal.desiredAccuracy = kCLLocationAccuracyBest
        gerenciadorLocal.requestWhenInUseAuthorization()
        gerenciadorLocal.startUpdatingLocation()
        
        
        //Configurando dados
        let bancoDados = Database.database().reference()
        let requisicoes = bancoDados.child("Requisicoes")
        
        //Recuperar arquivos
        requisicoes.observe(.childAdded) { (snapshot) in
            self.listaRequisicoes.append(snapshot)
            self.tableView.reloadData()
        }
        
        //Remover requisicao
        requisicoes.observe(.childRemoved) { (snapshot) in
            var indice = 0
            for requisicao in self.listaRequisicoes {
                if requisicao.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice)
                }
                indice += 1
            }
            
            self.tableView.reloadData()
        }

    }
    
    //Obtendo a localizacao do GPS
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordenadas = manager.location?.coordinate {
            localizacaodoMotorista = coordenadas
        }
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = listaRequisicoes[indexPath.row]
        performSegue(withIdentifier: segueVaiParaAceitarCorrida, sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let motoristaLocalizacao = localizacaodoMotorista {
            if segue.identifier == segueVaiParaAceitarCorrida {
                if let confirmarDestino = segue.destination as? AceitarCorridaViewController {
                    // Recupera os dados do Passageiro e do motorista.
                    // Enviar os dados recuperados para a tela de aceitar a corrida.
                    if let snapshot = sender as? DataSnapshot  {
                        if let dados = snapshot.value as? [String:Any] {
                            if let latPassageiro = dados["Latitude"] as? Double {
                                if let lonPassageiro = dados["Longitude"] as? Double {
                                    if let nomePassageiro = dados["Nome"] as? String {
                                        if let emailPassageiro = dados["Email"] as? String {
                                            let localPassageiro = CLLocationCoordinate2D(latitude: latPassageiro, longitude: lonPassageiro)
                                            // Envia os dados para a próxima ViewController
                                            confirmarDestino.nomePassageiro = nomePassageiro
                                            confirmarDestino.emailPassageiro = emailPassageiro
                                            confirmarDestino.localizacaoPassageiro = localPassageiro
                                            // Envia os dados do motorista
                                            confirmarDestino.localizacaoMotorista = motoristaLocalizacao
                                            print(confirmarDestino)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let quantidadeRows = listaRequisicoes.count
        return quantidadeRows
    }
    
    //Ao selecionar a requisicao realizar a transfere
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "minhaCell", for: indexPath) as UITableViewCell
        let snapshot = listaRequisicoes[indexPath.row]
        if let dados = snapshot.value as? [String: Any] {
            
            //Obtendo a localizacao do passageiro e motorista
            if let longitude = dados["Longitude"] as? Double {
                if let latitude = dados["Latitude"] as? Double {
                    let passageiroLoc = CLLocation(latitude: latitude, longitude: longitude)
                    if let motoristaLocalizacao = localizacaodoMotorista {
                        let motoristaLoc = CLLocation(latitude: motoristaLocalizacao.latitude, longitude: motoristaLocalizacao.longitude)
                        let distanciaEmMetros = motoristaLoc.distance(from: passageiroLoc)
                        let distanciaFinal = NSNumber(value: distanciaEmMetros / 100)
                        
                        //Formatando numero para obter distancia mais aproximada
                        let formatter = NumberFormatter()
                        formatter.numberStyle = NumberFormatter.Style.decimal
                        formatter.roundingMode = NumberFormatter.RoundingMode.halfUp
                        formatter.maximumFractionDigits = 3
                        let roundedValue = formatter.string(from: distanciaFinal)
                        
                        //Preenchendo celulas com localizacao e NOME
                        print(String(describing: roundedValue))
                        let andamento = atualizandoRequisicao(index: indexPath.row)
                        cell.detailTextLabel?.text = "\(roundedValue!) KM de distância."
                        if let nomeRequisitante = dados["Nome"] as? String {
                            cell.textLabel?.text = "\(nomeRequisitante) \(andamento)"
                        }
                        
                        
                        //Caso nao seja possivel recuperar os dados solicitados, retornar o valor abaixo.
                    } else {
                        cell.detailTextLabel?.text = "Não foi possível acessar os dados de localização."
                        cell.textLabel?.text = "Erro"
                    }
                }
            }
        }
        return cell
    }
    
    func atualizandoRequisicao(index: Int) -> String{
        let snapshot = listaRequisicoes[index]
        var requisicaoMotorista = ""
        if let dados = snapshot.value as? [String: Any] {
            if let emailMotorista = dados["MotoristaEmail"] {
                requisicaoMotorista = "Em Andamento"
                return requisicaoMotorista
            }
        }
        return requisicaoMotorista
    }
    
    //Ao pressionar deslogar o usuário da conta.
    @IBAction func botaoSair(_ sender: Any) {
        let autenticacao = Auth.auth()
        do {
            try autenticacao.signOut()
            print("Deslogado com sucesso!")
            dismiss(animated: true, completion: nil)
        } catch {
            print("Erro ao deslogar da conta.")
        }
    }
    
}
