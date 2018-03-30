classdef RegistrationFacade < mlfsl.RegistrationFacade
	%% REGISTRATIONFACADE  

	%  $Revision$
 	%  was created 15-Feb-2016 17:06:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlraichle/src/+mlraichle.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties 
        input = { 'fdg' } %'ho1' 'ho2' 'oo1' 'oo2' 'oc1' 'oc2' }
    end
    
	methods
        function g = pet(this)
            if (isempty(this.pet_))
                this.pet_ = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells({ this.oc(1) this.oc(2) this.ho(1) this.ho(2) this.oo(1) this.oo(2) this.fdg }));
            end
            g = this.pet_;
        end
        function g = fdg(this)
            if (isempty(this.fdg_) && ismethod(this.sessionData_, 'fdg'))
                this.fdg_ = this.sessionData_.fdg;
            end
            g = this.fdg_;
        end
        
        %% ALGORITHM 1
        
        function product = registerTalairachOnPet(this)
            %% REGISTERTALAIRACHWITHPET
            %  @return product is a struct with products as fields.
            
            product = this.initialImaging;
            
            msrb = mlfsl.MultispectralRegistrationBuilder('sessionData', this.sessionData);
            msrb.sourceImage = product.talairach;
            msrb.referenceImage = product.petAtlas;
            msrb = msrb.registerSurjective;
            product.tal_on_atl = msrb.product;
            product.xfm_tal_on_atl = msrb.xfm;
            
            [oc1_on_atl,product.xfm_atl_on_oc1] = this.petRegisterAndInvertTransform(product.oc1, product.petAtlas);
            [oc2_on_atl,product.xfm_atl_on_oc2] = this.petRegisterAndInvertTransform(product.oc2, product.petAtlas);
            [ho1_on_atl,product.xfm_atl_on_ho1] = this.petRegisterAndInvertTransform(product.ho1, product.petAtlas);
            [ho2_on_atl,product.xfm_atl_on_ho2] = this.petRegisterAndInvertTransform(product.ho2, product.petAtlas);
            [oo1_on_atl,product.xfm_atl_on_oo1] = this.petRegisterAndInvertTransform(product.oo1, product.petAtlas);
            [oo2_on_atl,product.xfm_atl_on_oo2] = this.petRegisterAndInvertTransform(product.oo2, product.petAtlas);
            [fdg_on_atl,product.xfm_atl_on_fdg] = this.petRegisterAndInvertTransform(product.fdg, product.petAtlas);
            
            if (this.recursion)
                this.pet_ = mlpet.PETImagingContext( ...
                    this.annihilateEmptyCells( ...
                        {oc1_on_atl oc2_on_atl ho1_on_atl ho2_on_atl oo1_on_atl oo2_on_atl fdg_on_atl}));
            end
            
            product = this.finalTalairachProduct(product);
            save(this.checkpointFqfilename('registerTalairachOnPet'), 'product');
        end 
        function product = initialImaging(this)            
            product.talairach = this.talairach;
            product.oc1       = this.oc(1);
            product.oc2       = this.oc(2);
            product.ho1       = this.ho(1);
            product.ho2       = this.ho(2);
            product.oo1       = this.oo(1);
            product.oo2       = this.oo(2);
            product.fdg       = this.fdg;  
            product.petAtlas  = this.initialPetAtlas(product);
        end
        function atlas   = initialPetAtlas(this, product)
            pet = mlpet.PETImagingContext( ...
                this.annihilateEmptyCells({ ...
                    product.fdg product.ho1 product.ho2 product.oo1 product.oo2 product.oc1 product.oc2 }));
            iter = pet.createIterator;
            assert(iter.hasNext);
            atlas = iter.next.clone;            
            while (iter.hasNext)
                prb = mlpet.PETRegistrationBuilder('sessionData', this.sessionData);
                prb.sourceImage = iter.next;
                prb.referenceImage = atlas;
                prb = prb.registerBijective;
                atlas.add(prb.product);
                atlas = atlas.atlas;
            end            
            atlas.fileprefix = 'petAtlas';   
        end
        function product = finalTalairachProduct(this, product)    
            product.talairach_on_oc1 = this.transform(product.tal_on_atl, product.xfm_atl_on_oc1, product.oc1);
            product.talairach_on_oc2 = this.transform(product.tal_on_atl, product.xfm_atl_on_oc2, product.oc2);
            product.talairach_on_ho1 = this.transform(product.tal_on_atl, product.xfm_atl_on_ho1, product.ho1);
            product.talairach_on_ho2 = this.transform(product.tal_on_atl, product.xfm_atl_on_ho2, product.ho2);
            product.talairach_on_oo1 = this.transform(product.tal_on_atl, product.xfm_atl_on_oo1, product.oo1);
            product.talairach_on_oo2 = this.transform(product.tal_on_atl, product.xfm_atl_on_oo2, product.oo2);
            product.talairach_on_fdg = this.transform(product.tal_on_atl, product.xfm_atl_on_fdg, product.fdg);
        end
        function masks = masksTalairachOnProduct(this, msk, product)
            assert(all(msk.niftid.size == product.talairach.niftid.size));
            this.sessionData.ensureNIFTI_GZ(msk);
            
            t = 'transformNearestNeighbor';
            masks.talairach_on_atl = this.transform(msk,                    product.xfm_tal_on_atl, product.petAtlas, t);
            masks.talairach_on_oc1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oc1, product.oc1, t);
            masks.talairach_on_oc2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oc2, product.oc2, t);
            masks.talairach_on_ho1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_ho1, product.ho1, t);
            masks.talairach_on_ho2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_ho2, product.ho2, t);
            masks.talairach_on_oo1 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oo1, product.oo1, t);
            masks.talairach_on_oo2 = this.transform(masks.talairach_on_atl, product.xfm_atl_on_oo2, product.oo2, t);
            masks.talairach_on_fdg = this.transform(masks.talairach_on_atl, product.xfm_atl_on_fdg, product.fdg, t);
            save(this.checkpointFqfilename('masksTalairachOnProduct'), 'masks');
        end
        
        %% ALGORITHM 2
        
        function product = registerTalairachOnPet2(this)
            %% REGISTERTALAIRACHWITHPET2
            %  @return product is a struct with products as fields.
            
            product = this.initialImaging2;
            
            in     = this.input;
            out    = cellfun(@(x) ['talairach_on_' x],  in, 'UniformOutput', false);
            xfm    = cellfun(@(x) ['xfm_tal_on_' x],    in, 'UniformOutput', false);
            prexfm = cellfun(@(x) ['prexfm_tal_on_' x], in, 'UniformOutput', false);
            for idx = 1:length(in)
                try                     
                    msrb = mlfsl.MultispectralRegistrationBuilder('sessionData', this.sessionData);
                    msrb.sourceImage = product.talairach;
                    msrb.sourceWeight = product.brainweight;
                    msrb.referenceImage = product.(in{idx});
                    msrb = msrb.registerSurjective;
                    product.(out{idx}) = msrb.product;
                    product.(xfm{idx}) = msrb.xfm;
                    product.(prexfm{idx}) = msrb.prexfm;
                catch ME
                    handwarning(ME);
                end
            end
            
            save(this.checkpointFqfilename('registerTalairachOnPet2'), 'product');
        end 
        function product = initialImaging2(this)
            product.talairach   = this.talairach;
            product.brainweight = this.sessionData.assembleImagingWeight( ...
                                                   this.brain.ones, 0.5, this.brain.binarized, 0.5);
            in = this.input;             
            for p = 1:length(in)                          
                product.(in{p}) = this.assignProductField(in{p});
            end
        end
        function masks   = masksTalairachOnProduct2(this, msk, product)
            assert(all(msk.niftid.size == this.talairach.niftid.size));
            this.sessionData.ensureNIFTI_GZ(msk);
            
            t      = 'nearestneighbour';
            in     = this.input;
            out    = cellfun(@(x) ['talairach_on_' x],  in, 'UniformOutput', false);
            xfm    = cellfun(@(x) ['xfm_tal_on_' x],    in, 'UniformOutput', false);
            prexfm = cellfun(@(x) ['prexfm_tal_on_' x], in, 'UniformOutput', false);
            for idx = 1:length(in)
                try
                    masks.(out{idx}) = this.transform(msk, ...
                        {product.(prexfm{idx}) product.(xfm{idx})}, {product.(in{idx}) product.(in{idx})}, t);
                catch ME
                    handwarning(ME);
                end
            end
            
            save(this.checkpointFqfilename('masksTalairachOnProduct2'), 'masks');
        end
        
        function [mask,tal1] = repairMaskInSitu(this, pet, mask, mask0, frame)
            %% REPAIRMASKSINSITU
            %  @param pet is the dynamic PET.
            %  @param mask is the dynamic Talairach mask on dynamic PET.
            %  @param mask0 is the native-resolution Talairach mask.
            %  @param frame is the index of the defective frame.
            %  @returns mask is the repaired dynamic Talairach mask on dynamic PET.
            %  @returns tal1 is the replacement Talairach on the defective PET frame.
            
            assert(isa(pet,   'mlpet.PETImagingContext'));
            assert(isa(mask,  'mlfourd.ImagingContext'));
            assert(isa(mask0, 'mlfourd.ImagingContext'));
            assert(isnumeric(frame));
            
            [tal1,xfm1_tal_on_pet] = this.repairTalairachOnPetFrame(pet, frame);            
            maskUpdate = this.transform(mask0, xfm1_tal_on_pet, pet, 'transformNearestNeighbor');
            
            maskNii = mask.niftid;
            maskNii.img(:,:,:,frame) = maskUpdate.niftid.img;
            maskNii.append_fileprefix(sprintf('_repairedf%i', frame));
            maskNii.append_descrip(sprintf('RegistrationFacade.repairMasksInSitu repaired frame %i', frame));
            mask = mlfourd.ImagingContext(maskNii);
        end
        function [tal1,xfm1] = repairTalairachOnPetFrame(this, pet, frame) % mv to MultispectralRegistrationBuilder
            %% REPAIRFRAME
            %  @param pet is the dynamic PET ImagingContext needing repair.
            %  @param frame is the frame needing repair.
            %  @returns tal1 is the replacement Talairach on the defective PET frame.
            %  @returns xfm1 is the transformation for the replacement Talairach; use with repairMaskFrame.
            
            msrb = mlfsl.MultispectralRegistrationBuilder('sessionData', this.sessionData);
            msrb.sourceImage    = this.talairach;
            msrb.sourceWeight   = this.sessionData.assembleImagingWeight( ...
                                  this.brain.ones, 0.5, this.brain.binarized, 0.5);
            petNii = pet.niftid;
            petNii.img = petNii.img(:,:,:,frame);
            petNii.append_fileprefix(sprintf('_f%i', frame));
            petNii.append_descrip(sprintf('RegistrationFacade.repairTalairachOnPetFrame extracted frame %i', frame));
            msrb.referenceImage = mlpet.PETImagingContext(petNii);
            msrb = msrb.registerSurjective;
            tal1 = msrb.product;
            xfm1 = msrb.xfm;
        end
		  
 		function this = RegistrationFacade(varargin)
 			%% REGISTRATIONFACADE
 			%  Usage:  this = RegistrationFacade()

 			this = this@mlfsl.RegistrationFacade(varargin{:});
        end
        
    end 
    
    %% PRIVATE
    
    methods (Access = private)        
        function p = assignProductField(this, tag)
            try
                if (ismember(tag(end), { '1' '2' '3' '4' '5' '6' '7' '8' '9' }))
                    p.(tag) = this.(tag(1:end-1))(str2double(tag(end)));
                else
                    p.(tag) = this.(tag);
                end
            catch ME
                handwarning(ME);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

